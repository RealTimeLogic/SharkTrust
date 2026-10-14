<?lsp
if not (request:issecure() or app.localAdmin(request)) or request:method()~="POST" or not app.checkCsrf(request) then return response:senderror(403) end
local session=request:session()
if session then session:terminate() end
response:sendredirect"/"
?>
