<?lsp
 local ispost = request:method() == "POST"
 if ispost then
    local data=request:data()
    if app.checkCredentials(app.rwZoneT(page.zkey), data.ba_username, data.ba_password) then
       request:session(true).authenticated=true
       response:sendredirect"/manage"
    end
    ba.sleep(1000)
 end
?>
<h1>Zone Admin Login</h1>
<div class="card card-body bg-light">
  <?lsp= ispost and '<div class="alert alert-danger" role="alert">Incorrect credentials!</div>' or '' ?>
  <form method="post" id="login_form">
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
  <span><a style="float:right;color:gray" href="/recover">Forgot account?</a></span>
</div>
