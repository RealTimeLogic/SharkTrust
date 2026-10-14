-- One writer owns every transaction. Callbacks run after commit, off the writer.
local rw=require"rwfile"
local quote=luasql.quotestr
local M={}
local function exec(conn,sql)
   local result,err=conn:execute(sql)
   assert(result,err or "Database operation failed")
   return result
end
local function rows(conn,sql)
   local cursor=exec(conn,sql)
   local result={}
   while true do
      local row=cursor:fetch({},"a")
      if not row then break end
      result[#result+1]=row
   end
   cursor:close()
   return result
end
local function one(conn,sql) return rows(conn,sql)[1] end
local function json(value) return assert(ba.json.encode(value)) end
local function hex(bytes)
   return (ba.rndbs(bytes):gsub(".",function(c) return string.format("%02X",c:byte()) end))
end
local function key(value,length)
   return type(value)=="string" and #value==length and not value:find("[^%x]")
end
local function readLegacy(home)
   local zones,err=rw.json(home,"data/zones.json")
   assert(zones or not home:stat"data/zones.json" and (err=="notfound" or err=="enoent"),"Invalid legacy zone index")
   local result={zones={},devices={},certs={}}
   local seen,seenZones={},{}
   for name,zkey in pairs(zones or {}) do
      assert(key(zkey,64),"Invalid legacy zone key")
      local zone=rw.json(home,"data/z."..zkey..".json")
      assert(type(zone)=="table" and zone.zname==name and type(zone.uname)=="string" and
         type(zone.ha1)=="string" and type(zone.rtime)=="number" and type(zone.devices)=="table" and
         type(zone.certs)=="table","Invalid legacy zone record")
      result.zones[#result.zones+1]={key=zkey,record=zone}
      seenZones[zkey]=true
      for dname,dkey in pairs(zone.devices) do
         assert(key(dkey,20) and not seen[dkey],"Invalid legacy device relationship")
         local device=rw.json(home,"data/d."..dkey..".json")
         assert(type(device)=="table" and device.name==dname and type(device.ip)=="string" and
            type(device.wan)=="string" and type(device.atime)=="number" and
            (device.dns=="local" or device.dns=="wan" or device.dns=="both"),"Invalid legacy device record")
         seen[dkey]=true
         result.devices[#result.devices+1]={key=dkey,zone=zkey,record=device}
         if type(zone.certs[dname])=="string" then
            result.certs[#result.certs+1]={key=dkey,expires=zone.certs[dname]}
         end
      end
   end
   -- The originals remain a recovery snapshot; never silently lose orphan data.
   for name in home:files"data" do
      local dkey=name:match"^d%.(%x+)%.json$"
      local zkey=name:match"^z%.(%x+)%.json$"
      assert(not dkey or seen[dkey],"Orphan legacy device; repair data before migration")
      assert(not zkey or seenZones[zkey],"Orphan legacy zone; repair data before migration")
   end
   return result
end

function M.open(home,profile,admin,done)
   local path=home:realpath"data/portal.sqlite.db"
   local function read(sql)
      local env=luasql.sqlite()
      local conn,err=env:connect(path,"READONLY")
      if not conn then env:close() error(err) end
      conn:setbusytimeout(2000)
      local ok,value=pcall(rows,conn,sql)
      conn:close() env:close()
      if not ok then error(value) end
      return value
   end
   local version=home:stat"data/portal.sqlite.db" and tonumber(read("PRAGMA user_version")[1].user_version) or 0
   assert(version==0 or version==1,"Unsupported SharkTrust database version")
   local legacy=version==0 and readLegacy(home)
   local legacyAdmin
   if version==0 and not admin and home:stat"data/admin.json" then
      legacyAdmin=assert(rw.json(home,"data/admin.json"),"Invalid legacy administrator credentials; use -credentials to reset")
   end
   local api={ready=false}
   local writer=ba.thread.create()
   local env,conn,closed
   local function complete(callback,...)
      if callback then
         local args=table.pack(...)
         ba.thread.run(function() callback(table.unpack(args,1,args.n)) end)
      end
   end
   local function commit()
      for _=1,40 do
         local ok,err=conn:commit"IMMEDIATE"
         if ok then return end
         assert(err=="BUSY",err)
         ba.sleep(50)
      end
      error"Database is busy"
   end
   function api.write(task,callback)
      if closed or not api.ready then complete(callback,false,"Database unavailable") return end
      writer:run(function()
         local ok,value=pcall(function() local result=task(conn) commit() return result end)
         if not ok then
            local rolled=conn:rollback"IMMEDIATE"
            if not rolled then api.ready=false end
            trace("SharkTrust: database transaction failed")
         end
         complete(callback,ok,value)
      end)
   end
   function api.close()
      if closed then return end
      closed=true api.ready=false
      writer:run(function() if conn then conn:close() end if env then env:close() end end)
   end
   function api.meta(name)
      local row=read("SELECT value FROM meta WHERE name="..quote(name))[1]
      if not row then return end
      local value=ba.json.decode(row.value)
      assert(value~=nil,"Invalid saved portal configuration")
      return value
   end
   function api.setMeta(name,value,callback)
      local encoded=json(value)
      api.write(function(c) exec(c,"INSERT OR REPLACE INTO meta VALUES("..quote(name)..","..quote(encoded)..")") end,callback)
   end
   function api.deleteRenewal(name)
      api.write(function(c)
         exec(c,"DELETE FROM meta WHERE substr(name,1,8)='renewal:' AND substr(name,-"..(#name+1)..")="..quote(":"..name))
      end)
   end
   function api.zones()
      local result={}
      for _,z in ipairs(read"SELECT zname,zkey FROM zones") do result[z.zname]=z.zkey end
      return result
   end
   function api.zone(zkey)
      local zone=read("SELECT * FROM zones WHERE zkey="..quote(zkey))[1]
      if not zone then return end
      zone.rtime=tonumber(zone.rtime) zone.devices={} zone.certs={}
      for _,d in ipairs(read("SELECT d.name,d.dkey,c.expires FROM devices d LEFT JOIN certificates c ON c.dkey=d.dkey AND c.profile="..
         quote(profile).." WHERE d.zkey="..quote(zkey))) do
         zone.devices[d.name]=d.dkey zone.certs[d.name]=d.expires or 0
      end
      zone.sso=zone.sso and ba.json.decode(zone.sso)
      return zone
   end
   function api.device(dkey)
      local value=read("SELECT * FROM devices WHERE dkey="..quote(dkey))[1]
      if value then value.atime=tonumber(value.atime) end
      return value
   end
   function api.wan(zkey)
      local result={}
      for _,d in ipairs(read("SELECT name,ip,wan FROM devices WHERE zkey="..quote(zkey))) do
         result[d.wan]=result[d.wan] or {} result[d.wan][d.name]=d.ip
      end
      return result
   end
   function api.createZone(name,uname,ha1,callback)
      api.write(function(c)
         local zkey=hex(32)
         exec(c,"INSERT INTO zones(zkey,zname,uname,ha1,rtime) VALUES("..quote(zkey)..","..quote(name)..","..
            quote(uname)..","..quote(ha1)..","..os.time()..")")
         return zkey
      end,callback)
   end
   function api.dns(zkey)
      return read("SELECT name,ip,wan,dns FROM devices WHERE zkey="..quote(zkey).." ORDER BY name")
   end
   function api.updateZone(zkey,field,value,callback)
      assert(field=="ha1" or field=="sso")
      api.write(function(c)
         assert(exec(c,"UPDATE zones SET "..field.."="..quote(field=="sso" and json(value) or value)..
            " WHERE zkey="..quote(zkey))==1,"Zone not found")
      end,callback)
   end
   function api.register(zkey,device,callback)
      api.write(function(c)
         local zone=assert(one(c,"SELECT zname FROM zones WHERE zkey="..quote(zkey)),"Zone not found")
         local name,n=device.name,0
         while one(c,"SELECT dkey FROM devices WHERE zkey="..quote(zkey).." AND name="..quote(name)) do
            n=n+1 name=device.name..n
         end
         assert(#name<=63 and #name+1+#zone.zname<=253,"Device name too long")
         local dkey=hex(10)
         exec(c,"INSERT INTO devices VALUES("..quote(dkey)..","..quote(zkey)..","..quote(name)..","..
            quote(device.ip)..","..quote(device.wan)..","..quote(device.dns)..","..quote(device.info or "")..","..os.time()..")")
         return {dkey=dkey,name=name}
      end,callback)
   end
   function api.address(zkey,dkey,ip,wan,dns,callback)
      api.write(function(c)
         local old=assert(one(c,"SELECT * FROM devices WHERE dkey="..quote(dkey).." AND zkey="..quote(zkey)),"Device not found")
         exec(c,"UPDATE devices SET ip="..quote(ip)..",wan="..quote(wan)..",dns="..quote(dns)..",atime="..os.time().." WHERE dkey="..quote(dkey))
         return {name=old.name,changed=old.ip~=ip or old.wan~=wan or old.dns~=dns}
      end,callback)
   end
   function api.certificate(dkey,expires,callback)
      api.write(function(c)
         exec(c,"INSERT OR REPLACE INTO certificates VALUES("..quote(profile)..","..quote(dkey)..","..quote(expires)..")")
      end,callback)
   end
   function api.deleteDevices(zkey,keys,cutoff,callback)
      api.write(function(c)
         local removed={}
         for _,dkey in ipairs(keys) do
            local row=one(c,"SELECT * FROM devices WHERE zkey="..quote(zkey).." AND dkey="..quote(dkey))
            if row and (not cutoff or tonumber(row.atime)<cutoff) then
               exec(c,"DELETE FROM devices WHERE dkey="..quote(dkey)) removed[#removed+1]=row
            end
         end
         return removed
      end,callback)
   end
   function api.deleteZone(zkey,callback)
      api.write(function(c)
         local devices=rows(c,"SELECT * FROM devices WHERE zkey="..quote(zkey))
         assert(exec(c,"DELETE FROM zones WHERE zkey="..quote(zkey))==1,"Zone not found")
         return devices
      end,callback)
   end
   function api.users(zkey)
      return read("SELECT id,name,role,revision,subject FROM users WHERE zkey="..quote(zkey).." ORDER BY name")
   end
   function api.user(zkey,name)
      local user=read("SELECT * FROM users WHERE zkey="..quote(zkey).." AND name="..quote(name:lower()))[1]
      if user and user.password then user.password=ba.json.decode(user.password) end
      return user
   end
   function api.saveUser(zkey,name,role,password,subject,callback)
      api.write(function(c)
         local current=one(c,"SELECT * FROM users WHERE zkey="..quote(zkey).." AND name="..quote(name))
         local pwd=password and json(password) or current and current.password
         exec(c,"INSERT OR REPLACE INTO users(id,zkey,name,role,password,subject,revision) VALUES("..
            (current and current.id or "NULL")..","..quote(zkey)..","..quote(name)..","..quote(role)..","..
            (pwd and quote(pwd) or "NULL")..","..(subject and quote(subject) or "NULL")..","..quote(hex(16))..")")
      end,callback)
   end
   function api.deleteUser(zkey,name,callback)
      api.write(function(c) exec(c,"DELETE FROM users WHERE zkey="..quote(zkey).." AND name="..quote(name)) end,callback)
   end
   function api.inactive(zkey,cutoff)
      local values=read("SELECT dkey,name,ip,atime FROM devices WHERE zkey="..quote(zkey).." AND atime<"..assert(tonumber(cutoff)).." ORDER BY name")
      for _,d in ipairs(values) do d.atime=tonumber(d.atime) end
      return values
   end
   writer:run(function()
      local ok,err=pcall(function()
         env=luasql.sqlite() conn=assert(env:connect(path))
         conn:setbusytimeout(2000)
         exec(conn,"PRAGMA foreign_keys=ON")
         assert(conn:setautocommit"IMMEDIATE")
         if version==0 then
            exec(conn,"CREATE TABLE meta(name TEXT PRIMARY KEY,value TEXT NOT NULL)")
            exec(conn,"CREATE TABLE zones(zkey TEXT PRIMARY KEY,zname TEXT NOT NULL UNIQUE,uname TEXT NOT NULL,ha1 TEXT NOT NULL,rtime INTEGER NOT NULL,sso TEXT)")
            exec(conn,"CREATE TABLE devices(dkey TEXT PRIMARY KEY,zkey TEXT NOT NULL REFERENCES zones(zkey) ON DELETE CASCADE,name TEXT NOT NULL,ip TEXT NOT NULL,wan TEXT NOT NULL,dns TEXT NOT NULL,info TEXT NOT NULL,atime INTEGER NOT NULL,UNIQUE(zkey,name))")
            exec(conn,"CREATE TABLE certificates(profile TEXT NOT NULL,dkey TEXT NOT NULL REFERENCES devices(dkey) ON DELETE CASCADE,expires TEXT NOT NULL,PRIMARY KEY(profile,dkey))")
            exec(conn,"CREATE TABLE users(id INTEGER PRIMARY KEY,zkey TEXT NOT NULL REFERENCES zones(zkey) ON DELETE CASCADE,name TEXT NOT NULL,role TEXT NOT NULL CHECK(role IN ('viewer','operator','admin')),password TEXT,subject TEXT,revision TEXT NOT NULL,UNIQUE(zkey,name))")
            for _,z in ipairs(legacy.zones) do
               local v=z.record
               exec(conn,"INSERT INTO zones(zkey,zname,uname,ha1,rtime) VALUES("..quote(z.key)..","..quote(v.zname)..","..quote(v.uname)..","..quote(v.ha1)..","..v.rtime..")")
            end
            for _,d in ipairs(legacy.devices) do
               local v=d.record
               exec(conn,"INSERT INTO devices VALUES("..quote(d.key)..","..quote(d.zone)..","..quote(v.name)..","..quote(v.ip)..","..quote(v.wan)..","..quote(v.dns)..","..quote(v.info or "")..","..v.atime..")")
            end
            for _,c in ipairs(legacy.certs) do exec(conn,"INSERT INTO certificates VALUES("..quote(profile)..","..quote(c.key)..","..quote(c.expires)..")") end
            exec(conn,"INSERT INTO meta VALUES('migration',"..quote(json{time=os.time(),zones=#legacy.zones,devices=#legacy.devices,profile=profile})..")")
            exec(conn,"PRAGMA user_version=1")
         end
         local value=admin or legacyAdmin
         if value then exec(conn,"INSERT OR REPLACE INTO meta VALUES('administrator',"..quote(json(value))..")") end
         commit()
         api.ready=not closed
      end)
      if not ok then
         if conn then pcall(function() conn:rollback() conn:close() end) conn=nil end
         if env then env:close() env=nil end
      end
      complete(done,ok,err)
   end)
   return api
end
return M
