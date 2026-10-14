<?lsp
if not request:issecure() then return response:senderror(403) end
if request:method()~="GET" then return response:senderror(405) end
local zkey=app.rcZonesT()[app.host(request)]
local zone=zkey and app.rwZoneT(zkey)
local dname=request:data"name"
local dkey=zone and zone.devices[dname]
local device=dkey and app.rwDeviceT(dkey)
if not device then return response:senderror(404) end
local auth=app.authorized(request,zkey)
-- Public discovery is restricted to devices at the browser's WAN address.
if not auth and device.wan~=app.peername(request) then return response:senderror(404) end
response:setheader("Cache-Control","no-store")
response:json{atime=device.atime,info=device.info,
   exptime=app.convertUTCTime(zone.certs[dname]),canrem=app.authorized(request,zkey,"operator") and true or false}
?>
