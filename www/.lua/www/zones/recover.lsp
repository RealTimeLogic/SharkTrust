<?lsp
local zone=app.rwZoneT(page.zkey)
local session=request:session(true)
local data=request:method()=="POST" and request:data() or {}
local message
if data.state=="request" then
   local code=ba.rndbs(16):gsub(".",function(c) return string.format("%02X",c:byte()) end)
   session.recovery={zone=page.zkey,code=code,expires=os.time()+600,attempts=0}
   if type(data.email)=="string" and app.trim(data.email):lower()==zone.uname:lower() then
      local address,peer,zname=zone.uname,app.peername(request),page.zname
      ba.thread.run(function()
         require"log".sendmail{subject="Password reset for "..zname,to=address,
            body=string.format("A password reset was requested from %s. Ignore this email if you did not request it.\n\nSecurity code: %s\n\nThis code expires in ten minutes.",peer,code)}
      end)
   end
elseif data.state=="reset" then
   local recovery=session.recovery
   if recovery and recovery.zone==page.zkey and recovery.expires>os.time() and recovery.attempts<5 then
      recovery.attempts=recovery.attempts+1
      if data.code==recovery.code and data.zkey==page.zkey and
         type(data.password)=="string" and #data.password>=8 and data.password==data.password2 then
         zone.ha1=app.ha1(zone.uname,data.password)
         session.recovery=nil
         local done=app.writeRedirect(response,"/login")
         app.db.updateZone(page.zkey,"ha1",zone.ha1,function(ok)
            if ok then session:terminate() end
            done(ok)
         end)
         return
      end
   end
   message="Unable to reset the password. Check the code, zone key and matching passwords, or request a new code."
end
local recovery=session.recovery
local pending=recovery and recovery.expires>os.time() and recovery.attempts<5
?>
<div class="card card-body login-box">
<?lsp if message then ?><p class="alert alert-danger"><?lsp=message?></p><?lsp end ?>
<?lsp if pending then ?>
<p>If the address matches this zone, an email with a security code is on its way. The code expires in ten minutes.</p>
<form method="post">
  <input type="hidden" name="csrf" value="<?lsp=page.csrf?>">
  <input type="hidden" name="state" value="reset">
  <div class="form-group"><label for="code">Security code</label><input id="code" name="code" type="text" required autocomplete="one-time-code"></div>
  <div class="form-group"><label for="zkey">Zone key (64 hexadecimal characters)</label><input id="zkey" name="zkey" type="text" required minlength="64" maxlength="64"></div>
  <div class="form-group"><label for="password">New password</label><input id="password" name="password" type="password" required minlength="8" autocomplete="new-password"></div>
  <div class="form-group"><label for="password2">Confirm password</label><input id="password2" name="password2" type="password" required minlength="8" autocomplete="new-password"></div>
  <button class="btn btn-primary" type="submit">Reset password</button>
</form>
<?lsp else ?>
<p>Recover access using your zone email address and saved zone key.</p>
<form method="post">
  <input type="hidden" name="csrf" value="<?lsp=page.csrf?>">
  <input type="hidden" name="state" value="request">
  <div class="form-group"><label for="email">Email address</label><input id="email" name="email" type="email" required autocomplete="email"></div>
  <button class="btn btn-primary" type="submit">Send security code</button>
</form>
<?lsp end ?>
</div>
