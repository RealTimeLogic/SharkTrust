
-- Mini CMS for all registered zones

local parseLspPage,templatePage
local app,io=app,app.io -- must be a closure

local zWebT=require"rwfile".json(io,".lua/www/zones.json")
assert(zWebT, ".lua/www/zones.json parse error")
local menuT=zWebT.menu
local pagesT=zWebT.pages

local function cmsfunc(_ENV,relpath,zname,zkey)
   local path,page
   if zkey then
      local s = request:session()
      local auth = s and s.authenticated or false -- See login.lsp
      local link = #relpath == 0 and "." or relpath
      local pageT = pagesT[link]
      if not pageT or (not pageT.nologin and not auth) then response:sendredirect"/" end
      page={link=link,title=pageT.title,menuT=menuT,zname=zname,zkey=zkey,authenticated=auth}
      path=".lua/www/zones/"..pageT.path
      response:setheader("strict-transport-security","max-age=15552000; includeSubDomains")
   else
      page={title="No Zone",zname=zname}
      path=".lua/www/zones/no-zone.lsp"
   end
   page.lsp=parseLspPage(path)
   templatePage(_ENV,path,io,page,app)
   return true
end

local function init(lsp,template)
   parseLspPage,templatePage = lsp,template 
   return cmsfunc
end

return init
