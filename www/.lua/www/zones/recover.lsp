<h1>Recover Account</h1>
<?lsp
local fmt=string.format
local zname=request:header"host"
local zkey=app.rcZonesT()[zname]
local zT=app.rwZoneT(zkey)
if not zT then response:sendredirect("https://"..app.settingsT.dn) end
local data = request:method() == "POST" and app.xssfilter(app.trim(request:data())) or {}

local function encodeSecCode(code)
   local sbyte=string.byte
   return code:gsub(".",function(x) return fmt("%02X",sbyte(x)) end)
end


----------------------------------------------
local function emitEmailForm(emsg)
----------------------------------------------
?>
<div class="card card-body bg-light">
  <?lsp= emsg and '<div class="alert alert-danger" role="alert">'..emsg..'!</div>' or '' ?>
  <form method="post" id="login_form">
    <div class="form-group">
      <label for="email">Username:</label>
      <input type="hidden" name="state" value="SecurityCode" />
      <input type="text" name="email" class="form-control" id="email" placeholder="Enter your E-Mail address" autofocus required tabindex="1">
    </div>
    <input type="submit" class="btn btn-primary btn-block" value="Recover" tabindex="2">
  </form>
</div>
<?lsp
end -----------------------------------------

local function manageSetPassword()
   if zkey ~= data.zkey or app.aesdecode(data.PrivSecCode or "") ~= data.SecCode then
      return emitEmailForm"Incorrect Zone Key"
   end
   if data.password and data.password == data.password2 then
      zT.ha1=app.ha1(zT.uname, data.password)
      app.rwZoneT(zkey,zT)
      response:sendredirect"/login"
   end
      return emitEmailForm"Passwords do not match"
end

local function managePasswordForm()
----------------------------------------------
   if encodeSecCode(app.aesdecode(data.PrivSecCode or "") or "") ~= data.SecCode then
      return emitEmailForm"Incorrect Security Code"
   end
?>
<div class="card card-body bg-light">
  <form id="pwdform" method="post">
    <div class="form-group">
      <label for="zkey">Enter the 64 byte long zone key:</label>
      <input type="text" name="zkey" class="form-control" id="zkey" placeholder="Enter your Zone Key" autofocus required tabindex="1">
    </div>
    <div class="form-group">
      <label for="password">New Password:</label>
      <input class="form-control" placeholder="Enter new password" type="password" id="password" name="password" minlength="8" autofocus nowhitespace="true" tabindex="2" />
    </div>
    <div class="form-group">
      <label for="password2">Confirm Password:</label>
      <input class="form-control" placeholder="Repeat password" type="password" id="password2" name="password2" equalTo="#password" nowhitespace="true" tabindex="3"/>
    </div>
    <input type="hidden" name="state" value="SetPassword" />
    <input type="hidden" name="PrivSecCode" value="<?lsp=app.aesencode(data.SecCode)?>" />
    <input type="hidden" name="SecCode" value="<?lsp=data.SecCode?>" />
    <input type="submit" class="btn btn-primary btn-block" value="Set New Password" tabindex="4">
  </form>
</div>
<script>
$(function() {
    $("#pwdform").validate({
        rules: {
            password: "required",
            password2: { equalTo: "#password" }
        }
    });
});
</script> 
<script src="https://cdn.jsdelivr.net/npm/jquery-validation@1.17.0/dist/jquery.validate.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/jquery-validation@1.17.0/dist/additional-methods.min.js"></script>
<?lsp
end -----------------------------------------
local function manageSecurityCode()
----------------------------------------------
   local secCode=ba.rndbs(16)
   if data.email and data.email:lower() == zT.uname:lower() then
      local peer = request:peername()
      local function sendEmail()
         local send = require"log".sendmail
         send{
            subject="Password reset request for "..zname,
            to=zT.uname,
            body=fmt("A password reset request has been initiated from %s. You may simply discard this email if you did not initiate this request.\n\nTo reset your password, copy the following Security Code and paste the code into the web form.\n\nSecurity Code: %s", peer, encodeSecCode(secCode))
         }
         app.log(false,"Password reset request from %s, originating from %s",zname,peer) 
      end
      ba.thread.run(sendEmail)
   end
?>
<div class="card card-body bg-light">
  <form method="post" id="login_form">
    <div class="form-group">
      <label for="SecCode">Please check your email for a message with your code</label>
      <input type="text" name="SecCode" class="form-control" id="SecCode" placeholder="Enter your Security Code" autofocus required tabindex="1">
      <input type="hidden" name="state" value="PasswordForm" />
      <input type="hidden" name="PrivSecCode" value="<?lsp=app.aesencode(secCode)?>" />
    </div>
    <input type="submit" class="btn btn-primary btn-block" value="Submit" tabindex="2">
  </form>
</div>

<?lsp
end -----------------------------------------

local actions = {
   SetPassword=manageSetPassword,
   PasswordForm=managePasswordForm,
   SecurityCode=manageSecurityCode,
}

(actions[data.state] or emitEmailForm)()



?>


