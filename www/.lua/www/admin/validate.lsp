<?lsp local function emitInvalidKey() ?>

<p><br/></p>
<div class="d-flex justify-content-center">
<div class="alert alert-danger">
<h1>Invalid Validation Key</h1>
<p>Invalid key or key has expired.</p>
<p><a class="btn btn-primary" role="button" href="/">Request new validation</a></p>
</div>
</div>

<?lsp 
end
local function emitAlreadyReg() ?>

<p><br/></p>
<div class="d-flex justify-content-center">
<div class="alert alert-danger">
<h1>Domain In Use</h1>
<p>Domain already registered!</p>
<p><a class="btn btn-primary" role="button" href="/">Register new domain</a></p>
</div>
</div>
<?lsp

end
local ns=app.settingsT
local function emitInvalidDNS(rsp) ?>

<p><br/></p>
<div class="d-flex justify-content-center">
<div class="alert alert-danger">
<h1>Invalid Domain Name Servers</h1>
<p>The domain name servers for your domain must be set to:</p>
<table>
<tr><td>Name Server 1:</td><td><?lsp=ns.ns1?></td></tr>
<tr><td>Name Server 2:</td><td><?lsp=ns.ns2?></td></tr>
</table>
<p>Note that it may take up to 48 hours for DNS changes to propagate. Please keep the validation key and retry later.</p>
<p>Whois response:</p>
<pre><?lsp=rsp?></pre>
</div>
</div>
<?lsp

end
local function emitCredentialsForm(vk,email) ?>

<h1>Credentials:</h1>

<div class="card card-body bg-light">
<form id="pwdform" method="post">
<div class="form-group">
<label>Username:</label> <?lsp=email?>
</div>
<div class="form-group">
<label for="password">Admin Password:</label>
<input class="form-control" placeholder="Enter a password" type="password" id="password" name="password" minlength="8" autofocus nowhitespace="true" tabindex="1"/>
</div>
<div class="form-group">
<label for="password2">Confirm Password:</label>
<input class="form-control" placeholder="Repeat password" type="password" id="password2" name="password2" equalTo="#password" nowhitespace="true" tabindex="2">
</div>
<input type="hidden" name="v" value="<?lsp=vk?>">
<input id="changesub" class="btn btn-primary" type="submit" value="Submit" tabindex="3">
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
end

local function emitRegComplete()
?>

<p><br/></p>
<div class="d-flex justify-content-center">
<div class="alert alert-primary">
<h1>Registration Complete</h1>
<p>You will receive an email with additional instructions when your account is ready.</p>
</div>
</div>


<?lsp
end



local function sendRegCompletedEmail(email,zkey,domain)
   local send = require"log".sendmail
   send{
      subject="SharkTrust Account Information: "..domain,
      to=email,
      body=string.format("Your zone key:\n%s%sYour zone URL:\nhttps://%s%s",
                         zkey,
                         "\n\nPlease store the secret zone key in a safe and secure location. The zone key must be kept a secret!\n\nYou will not be able to recover your account should you lose the zone key.\n\n",
                         domain,
"\n\nNote: it may take time for the DNS settings to replicate across the Internet and the above URL may not be immediately accessible.")
   }
end


local function whois(domain)
   local tld=domain:match"(%.[^%.]+)$"
   local whoisfmt=
      "whois -h `whois -h whois.iana.org %s | egrep -e '^whois:' | sed -e 's/[[:space:]][[:space:]]*/ /g' | cut -d \" \" -f 2` %s"
   local rsp,n,e=ba.exec(string.format(whoisfmt,tld,domain))
   if not rsp then rsp = e or "FAILED" end
   return rsp
end

local function digTrace(domain)
   local rsp,n,e=ba.exec("dig @8.8.8.8 +trace NS "..domain)
   if not rsp then rsp = e or "FAILED" end
   return rsp
end


if request:method()=="POST" then
   local data=request:data()
   if data.v then
      local t=ba.json.decode(app.aesdecode(data.v) or "")
      if t then
         local email,domain=t.e,t.d
         if app.rcZonesT()[domain] then return emitAlreadyReg() end
         if data.password and data.password == data.password2 then
            local zkey=app.createZone(domain, email, data.password)
            local function send()
               ba.thread.run(function() sendRegCompletedEmail(email,zkey,domain) end)
            end
            ba.timer(send):set(120000,true)
            emitRegComplete()
            return
         else
            local rspl=digTrace(domain):lower()
            if rspl:find(ns.ns1,1,true) and rspl:find(ns.ns2,1,true) then
               emitCredentialsForm(data.v,email)
            else
               rspl=whois(domain):lower()
               if rspl:find(ns.ns1,1,true) and rspl:find(ns.ns2,1,true) then
                  emitCredentialsForm(data.v,email)
               else
                  emitInvalidDNS(rspl)
               end
            end
         end
         return
      end
      emitInvalidKey()
      return
   end
end
?>
<h1>Enter Validation Key</h1>
<div class="card card-body bg-light">
<form id="valform" method="post">
<div class="form-group">
<label for="email">Validation Key:</label>
<input class="form-control" placeholder="Validation Key" type="text" name="v" autofocus nowhitespace="true" tabindex="1">
</div>
<input id="changesub" class="btn btn-primary" type="submit" value="Submit" tabindex="2" />
 </form>
</div>
