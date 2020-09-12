local app=app -- Must be closure

local function parseLspPage(name)
   local func
   local fp,err=io:open(name)
   if fp then
      local data
      data,err = ba.parselsp(fp:read"*a")
      fp:close()
      if data then
         local func
         -- Compile Lua code
         func,err = load(data,name,"t")
         if func then return func end
      end
   end
   app.log(true,"parsing %s failed: %s",name,err)
   return function(_ENV) print(name,err) end
end
-- Cache the template page.
local templatePage=parseLspPage(".lua/www/template.lsp")

return parseLspPage,templatePage
