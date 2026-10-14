-- Isolate material by CA directory and environment; retain original PEMs.
local rw=require"rwfile"
local M={}
function M.open(home,profile,service,settings)
   local base="cert/profiles/"..profile
   for _,path in ipairs{"cert/profiles",base,base.."/devices"} do
      assert(home:stat(path) or home:mkdir(path),"Cannot create certificate profile directory")
   end
   local marker=rw.json(home,"cert/legacy-profile.json")
   assert(marker or not home:stat"cert/legacy-profile.json","Invalid legacy certificate profile")
   if not marker then
      local old=rw.json(home,"cert/account.json")
      local matches=type(old)=="table" and (old.directoryUrl==service.directoryUrl or
         not old.directoryUrl and not settings.directoryUrl and not settings.productionUrl and not settings.stagingUrl and old.production==service.production)
      if settings.importLegacy==true or matches or not old and service.directoryUrl=="https://acme-v02.api.letsencrypt.org/directory" and service.production then
         marker={profile=profile}
         assert(rw.json(home,"cert/legacy-profile.json",marker),"Cannot record legacy certificate profile")
      end
   end
   local api={base=base}
   function api.read(name,device)
      local stem=(device and "/devices/" or "/")..name
      local ks,cs=device and ".key" or ".key.pem",device and ".cert" or ".cert.pem"
      local key,cert=rw.file(home,base..stem..ks),rw.file(home,base..stem..cs)
      if not key and not cert and marker and marker.profile==profile then
         key,cert=rw.file(home,"cert"..stem..ks),rw.file(home,"cert"..stem..cs)
         if key and cert then assert(api.write(name,key,cert,device)) end
      end
      return key,cert
   end
   function api.write(name,key,cert,device)
      local stem=base..(device and "/devices/" or "/")..name
      local ok,err=rw.file(home,stem..(device and ".key" or ".key.pem"),key)
      if ok then ok,err=rw.file(home,stem..(device and ".cert" or ".cert.pem"),cert) end
      return ok,err
   end
   function api.remove(name,device)
      local suffix=(device and "/devices/" or "/")..name
      local ks,cs=device and ".key" or ".key.pem",device and ".cert" or ".cert.pem"
      home:remove("cert"..suffix..ks) home:remove("cert"..suffix..cs)
      for p in home:files"cert/profiles" do
         if p:match("^%x+$") then
            home:remove("cert/profiles/"..p..suffix..ks) home:remove("cert/profiles/"..p..suffix..cs)
         end
      end
   end
   return api
end
return M
