local delays={60,300,900,3600,21600}
local M={}
function M.ready(state,name) return not state[name] or state[name].at<=os.time() end
function M.finish(state,name,ok)
   if ok then state[name]=nil return end
   local count=math.min((state[name] and state[name].attempt or 0)+1,#delays)
   state[name]={attempt=count,at=os.time()+delays[count]}
end
return M
