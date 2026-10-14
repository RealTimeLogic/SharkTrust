-- Interpreter-only check: no listeners, portal startup, DNS changes or ACME orders.
local ok,err=pcall(function()
   assert(type(ba.parsecerttime)=="function","Mako certificate APIs are required")
   assert(type(ba.crypto.PBKDF2)=="function","Mako PBKDF2 is required")
   local engine=assert(require"acme/engine".create())
   assert(type(engine.renewalInfo)=="function","ACME ARI resources are required")
   assert(type(luasql.sqlite)=="function","SQLite support is required")
end)
if not ok then print(err) end
mako.exit(ok and 0 or 1)
