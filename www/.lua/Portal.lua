-- Browser helpers share authorization with the direct RPC endpoints.
local M={}
function M.install(app)
   local MicrosoftSSO=app.io:dofile(".lua/MicrosoftSSO.lua")
   function app.deferred(response,location)
      local deferred=response:deferred()
      return function(status,body)
         if not deferred:valid() then return end
         body=body and (type(body)=="table" and ba.json.encode(body) or body) or ""
         deferred:setstatus(status)
         deferred:setheader("Cache-Control","no-store")
         deferred:setheader("Content-Type","application/json; charset=utf-8")
         if location and status<400 then deferred:setheader("Location",location) end
         deferred:setcontentlength(#body) deferred:send(body) deferred:close()
      end
   end
   function app.writeRedirect(response,location)
      local finish=app.deferred(response,location)
      return function(ok) finish(ok and 303 or 500,ok and nil or {error="Unable to save the change"}) end
   end
   function app.validEmail(value)
      return type(value)=="string" and #value<=254 and value:match("^[%w.!#$%%&'*+/=?^_`{|}~-]+@[%w.-]+%.[%a]+$")~=nil
   end
   function app.uuid(value)
      return type(value)=="string" and value:match("^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$")~=nil
   end
   function app.sensitiveSession(request,zkey)
      local session=request:session(true)
      if session.sensitiveZone~=zkey then session.sensitiveAction=nil session.sensitiveZone=zkey end
      return session
   end
   local cache={}
   function app.ssoClose(host)
      if host then
         if cache[host] then cache[host].close() cache[host]=nil end
      else
         for _,value in pairs(cache) do value.close() end
         cache={}
      end
   end
   function app.sso(host)
      if cache[host] then return cache[host] end
      local zkey=app.rcZonesT()[host]
      local zone=zkey and app.rwZoneT(zkey)
      if not zone or not zone.sso or not zone.sso.enabled then return nil,"Single sign-on is not enabled" end
      local config=zone.sso
      config.redirect_uri="https://"..host.."/sso"
      local ok,value=pcall(MicrosoftSSO.init,config,{
         log=function() app.log(true,"Microsoft Entra sign-in requires attention for %s",host) end,
         notify=function(event)
            app.log(true,"Microsoft Entra credential status for %s: %s",host,event.kind)
            ba.thread.run(function()
               require"log".sendmail{to=zone.uname,subject="SharkTrust Microsoft Entra credential",
                  body=event.message.."\nZone: "..host}
            end)
         end})
      if not ok then return nil,"Single sign-on configuration is invalid" end
      cache[host]=value
      return value
   end
end
return M
