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
   return function(env) env.response:senderror(500) end
end
-- Cache the template page.
local template=parseLspPage(".lua/www/template.lsp")
local function templatePage(env,path,io,page,app)
   -- Run page actions before the dashboard can commit headers. This keeps
   -- redirects, sessions and downloads independent of the size of the shell.
   if page.link=="cgen" then return page.lsp(env,path,io,page,app) end
   env.response:setheader("Content-Type","text/html; charset=utf-8")
   local output={}
   local function emit(...)
      for i=1,select("#",...) do output[#output+1]=tostring(select(i,...)) end
   end
   local pageEnv=setmetatable({_emit=emit},{__index=env})
   page.lsp(pageEnv,path,io,page,app)
   if not env.response:valid() or env.response:committed() then return end
   page.lsp=function() env.response:write(table.concat(output)) end
   template(env,path,io,page,app)
end

return parseLspPage,templatePage
