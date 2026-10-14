<?lsp local function emitEmailNotValid() ?>
<p><br/></p>
<div class="d-flex justify-content-center">
<div class="alert alert-danger">
<h2>E-Mail address not accepted</h2>
<p>Please use your company email address.</p>
<p><a class="btn btn-primary" role="button" href='/'>Continue</a></p>
</div>
</div>
<?lsp end
local function emitEmailDispatched(email) ?>
<p><br/></p>
<div class="d-flex justify-content-center">
<div class="alert alert-primary">
<p>We have sent an email with setup instructions to <?lsp=app.xssfilter(email)?>.</p>
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
%s/validate
]]


if request:method() == "POST" then
   local data=request:data()
   if data.email and data.domain then
      data.email=app.trim(data.email):lower()
      data.domain=app.trim(data.domain):lower()
      if not app.validDomain(data.domain) or #data.email>254 or not data.email:match("^[^%s@<>]+@[^%s@<>]+%.[^%s@<>]+$") then
         return response:senderror(400)
      end
      if io:dofile".lua/freeproviders.lua"[data.email:match"@(.+)"] then
         emitEmailNotValid()
         return
      end
      local domain=data.domain:lower()
      local valkey=app.aesencode(ba.json.encode{e=data.email,d=domain,expires=os.time()+3600})
      local send = require"log".sendmail
      send{
         subject="SharkTrust E-Mail Validation",
         to=data.email,
         body=string.format(emailfmt, valkey, app.serverAddr())
      }
      emitEmailDispatched(data.email)
      return
   end
end
?>


<h2>Register</h2>
<p>Register for Real Time Logic's SharkTrust Service.</p>
<div class="card card-body">
<form id="valform" method="post">
<input type="hidden" name="csrf" value="<?lsp=page.csrf?>">
<div class="form-group">
<label for="domain">Domain Name:</label>
<input class="form-control" placeholder="Enter your domain name" type="text" id="domain" name="domain" minlength="3" autofocus required tabindex="1">
</div>
<div class="form-group">
<label for="email">Email Address:</label>
<input class="form-control" placeholder="Enter company email address" type="email" id="email" name="email" required tabindex="2">
</div>
<iframe class="license-frame" title="Service agreement" src="/license.html"></iframe>
<input id="changesub" class="btn btn-primary" type="submit" value="Accept and Sign Up" tabindex="3" />
 </form>
</div>
