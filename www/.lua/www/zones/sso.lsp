<?lsp
if not request:issecure() then return response:senderror(403) end
local sso,problem=app.sso(page.zname)
local data=request:data()
if sso then
   if data.code or data.error then
      local header,payload=sso.login(request)
      if header and type(payload)=="table" then
         local name=type(payload.preferred_username)=="string" and payload.preferred_username:lower()
         local user=name and app.db.user(page.zkey,name)
         if user and user.subject and type(payload.oid)=="string" and payload.oid:lower()==user.subject then
            app.login(request,page.zkey,user.name,false,user)
            return response:sendredirect"/manage"
         end
         problem="This Microsoft identity has not been granted access to the zone."
      else problem="Microsoft sign-in could not be completed. Try again or use your local password." end
   else
      local ok=sso.sendredirect(request)
      if ok then return end
      problem="Microsoft sign-in is initializing or requires attention. Try again shortly, or use your local password."
   end
end
response:setheader("Referrer-Policy","no-referrer")
?>
<div class="card card-body"><p class="alert alert-warning"><?lsp=app.xssfilter(problem)?></p><a class="btn btn-primary" href="/sso">Try Microsoft sign-in again</a> <a href="/login">Local sign-in</a></div>
