-- Mini CMS for the main SharkTrust pages

local parseLspPage,templatePage
local app,io=app,app.io -- must be a closure

local zWebT=require"rwfile".json(io,".lua/www/admin.json")
assert(zWebT, ".lua/www/zones.json parse error")
local menuT=zWebT.menu
local pagesT=zWebT.pages


local function cmsfunc(_ENV,relpath)
   local s = request:session()
   local auth = s and s.authenticated or false -- See login.lsp
   local link = #relpath == 0 and "." or relpath
   local pageT = pagesT[link]
   if not pageT then response:sendredirect"/" end
   if not pageT.nologin and not auth then response:sendredirect"/login" end
   local page={ -- Using LSP page table for a different purpose
      authenticated=auth,
      link=link,
      lsp=parseLspPage(".lua/www/admin/"..pageT.path),
      menuT=menuT,
      title=pageT.title,
      zkey=zkey,
      zname=zname,
   }
   response:setheader("strict-transport-security","max-age=15552000; includeSubDomains")
   templatePage(_ENV,path,io,page,app)
   return true
end

local function init(lsp,template)
   parseLspPage,templatePage = lsp,template 
   return cmsfunc
end

return init
