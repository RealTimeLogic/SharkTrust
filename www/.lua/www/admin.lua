-- Mini CMS for the main SharkTrust pages

local parseLspPage,templatePage
local app,io=app,app.io -- must be a closure

local zWebT=require"rwfile".json(io,".lua/www/admin.json")
assert(zWebT, ".lua/www/admin.json parse error")
local menuT=zWebT.menu
local pagesT=zWebT.pages


local function cmsfunc(_ENV,relpath)
   local auth = app.authorized(request)
   local link = #relpath == 0 and "." or relpath
   local pageT = pagesT[link]
   if not pageT then response:sendredirect("/",false,true) return true end
   if not pageT.nologin and not auth then response:sendredirect("/login",false,true) return true end
   local path=(pageT.shared and ".lua/www/" or ".lua/www/admin/")..pageT.path
   local page={
      authenticated=auth,
      csrf=app.csrf(request),
      link=link,
      lsp=parseLspPage(path),
      menuT=menuT,
      title=pageT.title,
   }
   if request:issecure() then response:setheader("strict-transport-security","max-age=15552000; includeSubDomains") end
   templatePage(_ENV,path,io,page,app)
   return true
end

local function init(lsp,template)
   parseLspPage,templatePage = lsp,template 
   return cmsfunc
end

return init
