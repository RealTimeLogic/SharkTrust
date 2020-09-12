<?lsp

-- Return the DevT (details) as JSON


local dname=request:data"name"
local zkey=app.rcZonesT()[request:header"host"]
if zkey and dname then
   local zoneT=app.rwZoneT(zkey)
   if zoneT then
      local dkey=zoneT.devices[dname]
      if dkey then
         local t=app.rwDeviceT(dkey)
         t.exptime=app.convertUTCTime(zoneT.certs[dname])
         local s = request:session()
         local auth=s and s.authenticated
         t.canrem = auth
         t.dkey = auth and dkey
         response:json(t)
      end
   end
end
response:senderror(404)

?>
