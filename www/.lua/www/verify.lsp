<?lsp
local zkey=page.zkey or app.rcZonesT()[request:data"zone"]
local zone=zkey and app.rwZoneT(zkey)
local purpose=request:data"purpose"
if not zone or not app.sensitive.purpose(purpose) or not
   (app.authorized(request) or app.authorized(request,zkey,"admin")) then return response:senderror(403) end
local session=app.sensitiveSession(request,zkey)
local destination=page.zkey and (purpose=="cgen" and "/cgen" or "/settings") or "/zone?name="..zone.zname
local message
if request:method()=="POST" then
   if request:data"action"=="send" then
      local challenge=app.sensitive.begin(session,purpose)
      if challenge then
         local address,code,name=zone.uname,challenge.code,zone.zname
         local finish=app.deferred(response,"/verify?purpose="..purpose.."&zone="..zone.zname)
         ba.thread.run(function()
            local ok=require"log".sendmail{to=address,subject="SharkTrust sensitive access: "..name,
               body="Security code: "..code.."\n\nThis code expires in ten minutes. Ignore it if you did not request access."}
            if not ok then session.sensitiveAction.challenge=nil end
            finish(ok and 303 or 503,ok and nil or {error="Unable to send verification email"})
         end)
         return
      end
      message="Please wait before requesting another code. At most five requests are allowed per hour in this session."
   elseif request:data"action"=="verify" then
      if app.sensitive.verify(session,purpose,request:data"code") then return response:sendredirect(destination) end
      message="The code is invalid or expired. Five failed attempts require a new code."
   end
end
?>
<div class="card card-body login-box">
<p>A code sent to the zone owner's email address is required to <?lsp=app.sensitive.purpose(purpose).description?>. Access lasts one minute and can be used once.</p>
<?lsp if message then ?><p class="alert alert-warning"><?lsp=message?></p><?lsp end ?>
<form method="post"><input type="hidden" name="csrf" value="<?lsp=page.csrf?>"><input type="hidden" name="purpose" value="<?lsp=purpose?>"><input type="hidden" name="zone" value="<?lsp=zone.zname?>">
<input type="hidden" name="action" value="send"><button class="btn btn-primary">Send email code</button></form>
<?lsp if app.sensitive.hasChallenge(session,purpose) then ?>
<form method="post"><input type="hidden" name="csrf" value="<?lsp=page.csrf?>"><input type="hidden" name="purpose" value="<?lsp=purpose?>"><input type="hidden" name="zone" value="<?lsp=zone.zname?>"><input type="hidden" name="action" value="verify">
<div class="form-group"><label for="code">Email code</label><input type="text" id="code" name="code" autocomplete="one-time-code" required maxlength="32"></div><button class="btn btn-primary">Verify access</button></form>
<?lsp end ?>
</div>
