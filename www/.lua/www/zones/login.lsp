<?lsp
 local ispost = request:method() == "POST"
 if ispost then
    local data=request:data()
    local ok,systemAdmin,user=app.checkCredentials(app.rwZoneT(page.zkey), data.ba_username, data.ba_password)
    if ok then
       app.login(request,page.zkey,user and user.name or data.ba_username,systemAdmin,user)
       return response:sendredirect"/manage"
    end
    ba.sleep(1000)
 end
?>
<h2>Zone Admin Login</h2>
<?lsp local zone=app.rwZoneT(page.zkey) if zone.sso and zone.sso.enabled then ?>
<p><a class="btn btn-primary" href="/sso">Sign in with Microsoft Entra</a></p>
<?lsp end ?>
<div class="card card-body">
  <?lsp= ispost and '<div class="alert alert-danger" role="alert">Incorrect credentials!</div>' or '' ?>
  <form method="post" id="login_form">
<input type="hidden" name="csrf" value="<?lsp=page.csrf?>">
    <div class="form-group">
      <label for="Username">Username:</label>
      <input type="text" name="ba_username" class="form-control" id="Username" placeholder="Enter your E-Mail address" autofocus required tabindex="1">
    </div>
    <div class="form-group">
      <label for="Password">Password:</label>
      <input type="password" name="ba_password" class="form-control" id="Password" placeholder="Enter your password" required tabindex="2">
    </div>
    <input type="submit" class="btn btn-primary btn-block" value="Enter" tabindex="3">
  </form>
  <span><a class="sensitive-note" href="/recover">Forgot account?</a></span>
</div>
