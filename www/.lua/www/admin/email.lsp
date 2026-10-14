<?lsp
if request:method()=="POST" then
   local address=request:data"email"
   if not app.validEmail(address) then return response:senderror(400) end
   local finish=app.deferred(response)
   ba.thread.run(function()
      local ok=require"log".sendmail{to=address,subject="SharkTrust email test",body="The SharkTrust portal's SMTP test completed successfully."}
      finish(ok and 200 or 502,{ok=ok and true or false,message=ok and "Email accepted by SMTP server" or "SMTP delivery failed; check server configuration"})
   end)
   return
end
?>
<div class="card card-body"><p>Send a test using this server's configured SMTP service. SMTP acceptance does not confirm arrival in the recipient's inbox.</p>
<form method="post" id="email-test"><input type="hidden" name="csrf" value="<?lsp=page.csrf?>"><div class="form-group"><label for="email">Recipient</label><input id="email" name="email" type="email" required></div><button class="btn btn-primary">Send test email</button></form><p id="email-result" role="status"></p></div>
<script>
document.getElementById('email-test').addEventListener('submit',async function(event) {
  event.preventDefault();
  const button=this.querySelector('button'), result=document.getElementById('email-result');
  button.disabled=true; result.textContent='Sending test email...';
  try {
    const response=await fetch('/email',{method:'POST',body:new URLSearchParams(new FormData(this))});
    const data=await response.json(); result.textContent=data.message || 'Email test failed.';
  } catch(error) { result.textContent='Email test failed. Please try again.'; }
  finally { button.disabled=false; }
});
</script>
