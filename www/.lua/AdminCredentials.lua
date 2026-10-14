-- A saved portal administrator takes precedence over legacy mako.conf users.
local iterations=600000
local M={}
local function hex(value)
   return (value:gsub(".",function(c) return string.format("%02x",c:byte()) end))
end
local function passwordValid(value)
   return type(value)=="string" and #value>=8 and #value<=1024 and not value:find("%z")
end
local function usernameValid(value)
   return type(value)=="string" and #value>0 and #value<=254 and
      not value:find("[%c:]") and not value:find("^%s") and not value:find("%s$")
end
local function derive(password,salt)
   local key=ba.crypto.PBKDF2("sha256",password,salt,iterations,32)
   return key and hex(key)
end
local function equal(left,right)
   if type(left)~="string" or #left~=#right then return false end
   local different=0
   for i=1,#left do different=different | (left:byte(i) ~ right:byte(i)) end
   return different==0
end

function M.password(name,password)
   if not usernameValid(name) or not passwordValid(password) then
      return nil,"Provide a username and an 8-1024 byte password"
   end
   local salt=hex(ba.rndbs(16))
   local hash=derive(password,salt)
   if not hash then return nil,"Cannot hash password" end
   return {version=1,username=name,salt=salt,hash=hash,iterations=iterations}
end

function M.prepare(argv)
   local supplied
   for i,arg in ipairs(argv or {}) do
      if arg=="-credentials" then
         if supplied or type(argv[i+1])~="string" then
            return nil,"Use -credentials username:password exactly once"
         end
         supplied=argv[i+1]
      end
   end
   if supplied then
      local name,password=supplied:match("^([^:]+):(.*)$")
      local saved=M.password(name,password)
      if not saved then return nil,"Invalid -credentials: provide username:password with an 8-1024 byte password" end
      return saved
   end
   return false
end

function M.checker(saved,users,ha1)
   if saved~=nil then
      if type(saved)~="table" or saved.version~=1 or not usernameValid(saved.username) or
         saved.iterations~=iterations or type(saved.salt)~="string" or #saved.salt~=32 or
         saved.salt:find("[^0-9a-f]") or type(saved.hash)~="string" or #saved.hash~=64 or
         saved.hash:find("[^0-9a-f]") then
         return nil,"Invalid portal administrator credentials; use -credentials to reset"
      end
      return function(name,password)
         return name==saved.username and passwordValid(password) and equal(derive(password,saved.salt),saved.hash) or false
      end
   end
   return function(name,password)
      if type(name)~="string" or type(password)~="string" then return false end
      local p=type(users)=="table" and users[name]
      if type(p)=="table" then return p[1]==ha1(name,password) end
      return type(p)=="string" and p==password
   end
end

return M
