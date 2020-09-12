<?lsp

-- Remove device if zone admin.

local s = request:session()
if not s or not s.authenticated then
   response:json{ok=false}
end

local dname=request:data"name"
local zname=request:header"host"
local zkey=app.rcZonesT()[zname]
if zkey and dname then
   local zoneT=app.rwZoneT(zkey)
   if zoneT then
      local dkey=zoneT.devices[dname]
      if dkey then
         app.deleteDevice(zname, zkey, dname, dkey)
         response:json{ok=true}
      end
   end
end
response:senderror(404)

?>
