<?lsp local function emitEmailNotValid() ?>
<p><br/></p>
<div class="d-flex justify-content-center">
<div class="alert alert-danger">
<h1>E-Mail address not accepted</h1>
<p>Please use your company email address.</p>
<p><a class="btn btn-primary" role="button" href='/'>Continue</a></p>
</div>
</div>
<?lsp end
local function emitEmailDispatched(email) ?>
<p><br/></p>
<div class="d-flex justify-content-center">
<div class="alert alert-primary">
<p>We have sent an email with setup instructions to <?lsp=email?>.</p>
<p>Please check your spam box and/or spam filters if you do not receive this email soon.</p>
</div>
</div>
<?lsp end?>

<?lsp

local emailfmt=[[

Validation key:
%s

Complete the validation by navigating to the following URL and by
entering the validation key:
https://%s/validate
]]


if request:method() == "POST" then
   local data=request:data()
   if data.email and data.domain then
      if io:dofile".lua/freeproviders.lua"[data.email:match"@(.+)"] then
         emitEmailNotValid()
         return
      end
      local domain=data.domain:lower()
      local valkey=app.aesencode(ba.json.encode{e=data.email,d=domain})
      local send = require"log".sendmail
      send{
         subject="SharkTrust E-Mail Validation",
         to=data.email,
         body=string.format(emailfmt, valkey, app.settingsT.dn)
      }
      emitEmailDispatched(data.email)
      return
   end
end
?>


<h1>Register</h1>
<p>Register for Real Time Logic's SharkTrust Service.</p>
<div class="card card-body bg-light">
<form id="valform" method="post">
<div class="form-group">
<label for="email">Domain Name:</label>
<input class="form-control" placeholder="Enter your domain name" type="text" name="domain" minlength="7" autofocus nowhitespace="true" tabindex="1">
</div>
<div class="form-group">
<label for="email">Email Address:</label>
<input class="form-control" placeholder="Enter company email address" type="text" name="email" minlength="9" nowhitespace="true" tabindex="2">
</div>
<iframe style="width:100%;height:300px" src="license.html"></iframe>
<input id="changesub" class="btn btn-primary" type="submit" value="Accept and Sign Up" tabindex="3" />
 </form>
</div>
<script>
$(function() {
    $("#valform").validate({
        rules: {
            domain: "required",
            email: { required: true, email: true },
        }
    });
});
</script>
<script src="https://cdn.jsdelivr.net/npm/jquery-validation@1.17.0/dist/jquery.validate.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/jquery-validation@1.17.0/dist/additional-methods.min.js"></script>

