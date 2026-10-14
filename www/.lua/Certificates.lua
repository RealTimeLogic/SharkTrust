-- Each order owns its engine and challenge. Device keys must be exportable:
-- the SharkTrust binary protocol delivers the private key to the device.
local Engine=require"acme/engine"
assert(type(Engine.create)=="function", "Upgrade mako.zip: current ACME engine required")
local rw=require"rwfile"
local M={}

function M.info(cert)
   local body=type(cert)=="string" and cert:match("%-%-%-%-%-BEGIN CERTIFICATE%-%-%-%-%-%s*(.-)%s*%-%-%-%-%-END CERTIFICATE%-%-%-%-%-")
   if not body then return end
   local ok,info=pcall(function() return ba.parsecert(ba.b64decode((body:gsub("%s","")))) end)
   if ok and info then return info end
end

function M.expires(cert)
   local info=M.info(cert)
   return info and ba.parsecerttime(info.tzto) or 0
end

function M.renewAt(cert)
   local info=M.info(cert)
   if not info then return 0 end
   local expires,issued=ba.parsecerttime(info.tzto),ba.parsecerttime(info.tzfrom)
   -- Short-lived certificates must not renew continuously with a fixed lead.
   return expires-math.min(22*86400,math.max(0,expires-issued)/3)
end
function M.due(cert) return M.renewAt(cert)<=os.time() end

function M.profile(settings)
   local service={production=settings.production~=false,
      productionUrl=settings.productionUrl,stagingUrl=settings.stagingUrl}
   service.directoryUrl=settings.directoryUrl or (service.production and (service.productionUrl or "https://acme-v02.api.letsencrypt.org/directory") or
      (service.stagingUrl or "https://acme-staging-v02.api.letsencrypt.org/directory"))
   assert(type(service.directoryUrl)=="string" and service.directoryUrl:match("^https://[^/]+/") and
      not service.directoryUrl:find("[%s@#]"),"ACME directoryUrl must be an HTTPS URL without credentials or fragments")
   -- The BAS engine resolves its directory from these public service fields.
   if service.production then service.productionUrl=service.directoryUrl else service.stagingUrl=service.directoryUrl end
   return ba.crypto.hash"sha256"((service.production and "production:" or "staging:")..service.directoryUrl)(true,"hex"),service
end

function M.create(home,settings,email)
   local profile,service=M.profile(settings)
   local accountPath="cert/account-"..ba.crypto.hash"sha256"(service.directoryUrl)(true,"hex")..".json"
   local account=rw.json(home,accountPath)
   assert(account or not home:stat(accountPath),"Invalid saved ACME account")
   assert(not account or type(account)=="table" and type(account.key)=="string" and
      account.key:find("-----BEGIN",1,true),"Invalid saved ACME software account")
   if not account then
      local old=rw.json(home,"cert/account.json")
      -- Preserve a legacy software account only for its original CA profile.
      if type(old)=="table" and type(old.key)=="string" and old.key:find("-----BEGIN",1,true) and
         (old.directoryUrl==service.directoryUrl or not old.directoryUrl and
          not settings.directoryUrl and not settings.productionUrl and not settings.stagingUrl and old.production==service.production) then
         account={key=old.key,url=old.url or old.id,directoryUrl=service.directoryUrl,email=email}
      else
         account={email=email,key=assert(ba.create.key{key="ecc",curve="SECP256R1"})}
      end
      assert(rw.json(home,accountPath,account),"Cannot save ACME account")
   end
   local active,closed={},false
   local api={profile=profile,service=service}
   local database
   local renewal,queries,saves={},{},{}
   local queryCount=0
   local function finite(value)
      return type(value)=="number" and value==value and math.abs(value)<math.huge
   end
   local function metaKey(name) return "renewal:"..profile..":"..name end
   local function persist(name,state)
      local pending={at=os.time()+60}
      saves[name]=pending
      database.setMeta(metaKey(name),state,function(ok)
         if saves[name]==pending then
            if ok then saves[name]=nil
            else trace("SharkTrust: cannot save certificate renewal schedule") end
         end
      end)
   end
   local function cancelQuery(name)
      local query=queries[name]
      if query then
         queries[name]=nil queryCount=queryCount-1
         query.engine:close()
      end
   end
   local function refresh(name,cert,state)
      if closed or queries[name] or active[name] or queryCount>=4 then return end
      local engine=Engine.create()
      if not engine then
         state.renewAt=math.min(state.renewAt,M.renewAt(cert))
         state.checkAt=os.time()+21600
         persist(name,state)
         return
      end
      local query={engine=engine}
      queries[name]=query queryCount=queryCount+1
      local function finish(info)
         if queries[name]~=query then return end
         queries[name]=nil queryCount=queryCount-1
         engine:close()
         if closed or renewal[name]~=state then return end
         local now,expires=os.time(),M.expires(cert)
         local window=info and info.suggestedWindow
         local first,last=window and window.start,window and window["end"]
         if finite(first) and finite(last) and first<last and last<=expires and
            type(info.ariId)=="string" and #info.ariId>0 then
            -- Keep the selected instant while the CA's window is unchanged.
            if state.windowStart~=first or state.windowEnd~=last then
               state.renewAt=math.min(expires-1,math.max(now,math.floor(first+math.random()*(last-first))))
            end
            state.windowStart,state.windowEnd,state.ariId=first,last,info.ariId
            state.checkAt=now+math.max(60,math.min(86400,finite(info.retryAfter) and info.retryAfter or 21600))
         else
            -- An outage must not postpone an earlier, already selected renewal.
            state.renewAt=math.min(state.renewAt,M.renewAt(cert))
            state.checkAt=now+21600
         end
         persist(name,state)
      end
      local called,accepted=pcall(function()
         return engine:renewalInfo(service,{certificate=cert,ariId=state.ariId},finish)
      end)
      if not called or not accepted then finish() end
   end
   -- The existing SQLite writer owns schedule persistence as well as portal data.
   function api.start(db) database=db end
   function api.due(name,cert)
      if closed then return false end
      if not cert or M.expires(cert)==0 then
         cancelQuery(name) renewal[name]=nil
         return true
      end
      local fingerprint=ba.crypto.hash"sha256"(cert)(true,"hex")
      local state=renewal[name]
      if not state or state.fingerprint~=fingerprint then
         cancelQuery(name)
         local ok,saved=pcall(database.meta,metaKey(name))
         if ok and type(saved)=="table" and saved.fingerprint==fingerprint and
            finite(saved.renewAt) and saved.renewAt<M.expires(cert) and finite(saved.checkAt) and
            saved.checkAt>=0 and saved.checkAt<=os.time()+86400 and
            (saved.ariId==nil or type(saved.ariId)=="string") then state=saved
         else state={fingerprint=fingerprint,renewAt=M.renewAt(cert),checkAt=0} end
         renewal[name]=state
      end
      local now=os.time()
      if saves[name] and saves[name].at<=now then persist(name,state) end
      if M.expires(cert)<=now or state.checkAt>0 and state.renewAt<=now then return true end
      if state.checkAt<=now then refresh(name,cert,state) end
      -- Wait for the first lookup of a valid certificate, never for an expired one.
      return not (queries[name] and state.checkAt==0) and state.renewAt<=now
   end
   function api.installed(name,cert,ariId)
      if closed then return end
      cancelQuery(name)
      local state={fingerprint=ba.crypto.hash"sha256"(cert)(true,"hex"),
         renewAt=M.renewAt(cert),checkAt=0,ariId=ariId}
      renewal[name]=state
      persist(name,state)
      refresh(name,cert,state)
   end

   function api.request(name,key,challenge,done)
      if closed or active[name] then done(false,"Certificate request unavailable") return end
      local engine=assert(Engine.create())
      local entry={engine=engine}
      active[name]=entry
      local function finish(result,problem)
         if entry.finished then return end
         entry.finished=true
         if problem then result=nil end
         active[name]=nil
         engine:close()
         if result and not closed then
            local ok,err=rw.json(home,accountPath,result.account)
            if ok then account=result.account else result,problem=nil,err end
         end
         if closed then done(false,"Certificate service stopped")
         elseif result then done(result)
         else done(false,type(problem)=="table" and (problem.message or problem.code) or tostring(problem)) end
      end
      local ok,job,err=pcall(function()
         -- Explicit software key bypasses the engine's automatic TPM selection.
         local privateKey,keyErr=key
         if not privateKey then privateKey,keyErr=ba.create.key(settings.rsa and
            {key="rsa",bits=settings.bits or 2048} or {key="ecc",curve=settings.curve or "SECP384R1"}) end
         if not privateKey then return nil,keyErr end
         return engine:certificate(service,account,{domain=name,acceptTerms=true,
            key={privateKey=privateKey},challenge=challenge,
            replaces=renewal[name] and renewal[name].ariId},finish)
      end)
      if not ok then finish(nil,job) elseif not job then finish(nil,err) end
      entry.job=job
   end

   function api.cancel(name)
      cancelQuery(name)
      renewal[name],saves[name]=nil,nil
      if database then database.deleteRenewal(name) end
      local entry=active[name]
      if entry then entry.engine:close() end
   end

   function api.close()
      closed=true
      local names={}
      for name in pairs(queries) do names[#names+1]=name end
      for _,name in ipairs(names) do cancelQuery(name) end
      local engines={}
      for _,entry in pairs(active) do engines[#engines+1]=entry.engine end
      for _,engine in ipairs(engines) do engine:close() end
   end

   return api
end

return M
