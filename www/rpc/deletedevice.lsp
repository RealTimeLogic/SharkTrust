<?lsp
if not request:issecure() then return response:senderror(403) end
if request:method()~="POST" then response:setheader("Allow","POST") return response:senderror(405) end
local zname=app.host(request)
local zkey=app.rcZonesT()[zname]
if not zkey or not app.authorized(request,zkey,"operator") or not app.checkCsrf(request) then return response:senderror(403) end
local dname=request:data"name"
local zone=app.rwZoneT(zkey)
local dkey=zone and zone.devices[dname]
if not dkey then return response:senderror(404) end
local done=app.deferred(response)
app.deleteDevice(zname,zkey,dname,dkey,function(ok) done(ok and 200 or 500,{ok=ok}) end)
?>
