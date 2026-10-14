<?lsp local function emitInvalidKey() ?>

<p><br/></p>
<div class="d-flex justify-content-center">
<div class="alert alert-danger">
<h2>Invalid Validation Key</h2>
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
<h2>Domain In Use</h2>
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
<h2>DNS Delegation Not Confirmed</h2>
<p>The parent DNS zone must delegate your domain to:</p>
<table>
<tr><td>Name Server 1:</td><td><?lsp=ns.ns1?></td></tr>
<tr><td>Name Server 2:</td><td><?lsp=ns.ns2?></td></tr>
</table>
<p>If you recently changed the delegation, keep the validation key and retry after the DNS change is visible.</p>
<p>If the lookup failed, the portal administrator should check that <code>dig</code> is installed and outbound DNS is available.</p>
<p>DNS lookup details:</p>
<pre><?lsp=app.xssfilter(rsp)?></pre>
</div>
</div>
<?lsp

end
local function emitCredentialsForm(vk,email) ?>

<h2>Credentials:</h2>

<div class="card card-body">
<form id="pwdform" method="post">
<input type="hidden" name="csrf" value="<?lsp=page.csrf?>">
<div class="form-group">
<label>Username:</label> <?lsp=app.xssfilter(email)?>
</div>
<div class="form-group">
<label for="password">Admin Password:</label>
<input class="form-control" placeholder="Enter a password" type="password" id="password" name="password" minlength="8" autofocus required tabindex="1"/>
</div>
<div class="form-group">
<label for="password2">Confirm Password:</label>
<input class="form-control" placeholder="Repeat password" type="password" id="password2" name="password2"  required tabindex="2">
</div>
<input type="hidden" name="v" value="<?lsp=app.xssfilter(vk)?>">
<input id="changesub" class="btn btn-primary" type="submit" value="Submit" tabindex="3">
 </form>
</div>
<?lsp
end

local function emitRegComplete()
?>

<p><br/></p>
<div class="d-flex justify-content-center">
<div class="alert alert-primary">
<h2>Registration Complete</h2>
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


local function checkDNS(domain)
   -- The caller validates domain with app.validDomain before using it here.
   local rsp,err,detail=ba.exec("dig -r -4 @8.8.8.8 +trace +nodnssec +time=2 +tries=1 NS "..domain)
   rsp=rsp or detail
   if not rsp then return false,"DNS lookup failed: "..tostring(err) end
   local found={}
   for line in rsp:gmatch("[^\r\n]+") do
      local owner,target=line:lower():match("^(%S+)%s+%d+%s+in%s+ns%s+(%S+)%s*$")
      if owner and owner:gsub("%.$","")==domain then
         found[target:gsub("%.$","")]=true
      end
      -- Use the first matching RRset: the parent delegation is available even
      -- before registration creates the child zone on our name servers.
      if next(found) and line:match("^;; Received ") then break end
   end
   return not not (found[ns.ns1:lower():gsub("%.$","")] and
                   found[ns.ns2:lower():gsub("%.$","")]),rsp
end


if request:method()=="POST" then
   local data=request:data()
   if data.v then
      local t=ba.json.decode(app.aesdecode(data.v) or "")
      if type(t)=="table" and type(t.expires)=="number" and t.expires>os.time() and app.validDomain(t.d) and type(t.e)=="string" then
         local email,domain=t.e,t.d
         if app.rcZonesT()[domain] then return emitAlreadyReg() end
         local valid,rsp=checkDNS(domain)
         if not valid then return emitInvalidDNS(rsp) end
         if data.password and #data.password>=8 and data.password == data.password2 then
            local session=request:session(true)
            local done=app.deferred(response,"/validate")
            app.createZone(domain,email,data.password,function(ok,zkey)
               if ok then app.later(120000,function()
                  ba.thread.run(function() sendRegCompletedEmail(email,zkey,domain) end)
               end) end
               if ok then session.registrationComplete=true end
               done(ok and 303 or 500,ok and nil or {error="Registration failed"})
            end)
            return
         else
            emitCredentialsForm(data.v,email)
         end
         return
      end
      emitInvalidKey()
      return
   end
end
local session=request:session()
if session and session.registrationComplete then
   session.registrationComplete=nil
   emitRegComplete()
   return
end
?>
<h2>Enter Validation Key</h2>
<div class="card card-body">
<form id="valform" method="post">
<input type="hidden" name="csrf" value="<?lsp=page.csrf?>">
<div class="form-group">
<label for="email">Validation Key:</label>
<input class="form-control" placeholder="Validation Key" type="text" name="v" autofocus required tabindex="1">
</div>
<input id="changesub" class="btn btn-primary" type="submit" value="Submit" tabindex="2" />
 </form>
</div>
