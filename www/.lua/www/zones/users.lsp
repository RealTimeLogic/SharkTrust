<?lsp
local zone=app.rwZoneT(page.zkey)
local data=request:data()
local message
if request:method()=="POST" then
   if data.action=="save" then
      local name=type(data.email)=="string" and data.email:lower()
      local role=data.role
      if not app.validEmail(name) or name==zone.uname:lower() or not ({viewer=true,operator=true,admin=true})[role] then
         message="Enter another user's email address and select a role."
      else
         local password
         if data.password and #data.password>0 then password=app.credentials.password(name,data.password) end
         local subject=data.subject and data.subject:lower()
         if subject=="" then subject=nil end
         local current=app.db.user(page.zkey,name)
         if (data.password and #data.password>0 and not password) or (subject and not app.uuid(subject)) or
            not (password or current and current.password or subject) then
            message="Provide an 8-1024 byte password or the user's Microsoft Entra object ID."
         else
            app.db.saveUser(page.zkey,name,role,password,subject,app.writeRedirect(response,"/users"))
            return
         end
      end
   elseif data.action=="delete" then
      if not app.validEmail(data.email) then return response:senderror(400) end
      app.db.deleteUser(page.zkey,data.email:lower(),app.writeRedirect(response,"/users"))
      return
   elseif data.action=="sso" then
      local config={enabled=data.enabled=="yes"}
      if config.enabled then
         config.tenant=data.tenant config.client_id=data.client_id
         config.client_secret=data.secret~="" and data.secret or zone.sso and zone.sso.client_secret
         config.client_secret_expires=data.expires
         if not app.uuid(config.tenant) or not app.uuid(config.client_id) or type(config.client_secret)~="string" or
            #config.client_secret==0 or #config.client_secret>512 or not (config.client_secret_expires or ""):match("^%d%d%d%d%-%d%d%-%d%d$") or
            not ba.datetime(config.client_secret_expires.."T23:59:59Z") then
            message="Provide the tenant ID, application ID, client secret and its expiration date."
         end
      end
      if not message then
         local host=page.zname
         local done=app.writeRedirect(response,"/users")
         app.db.updateZone(page.zkey,"sso",config,function(ok) if ok then app.ssoClose(host) end done(ok) end)
         return
      end
   end
end
local config=zone.sso or {}
?>
<?lsp if message then ?><p class="alert alert-warning"><?lsp=message?></p><?lsp end ?>
<div class="card card-body"><p>Viewers can see devices. Operators can also remove devices and review inactive-device cleanup. Zone administrators can manage users, sign-in settings and zone credentials.</p>
<p>The zone owner remains <?lsp=app.xssfilter(zone.uname)?>. Role changes, password changes and user removal invalidate that user's existing sessions.</p>
<div class="table-wrap"><table class="table table-striped table-bordered"><thead><tr><th>Email</th><th>Role</th><th>Entra object ID</th><th>Remove</th></tr></thead><tbody>
<?lsp for _,user in ipairs(app.db.users(page.zkey)) do ?>
<tr><td><?lsp=app.xssfilter(user.name)?></td><td><?lsp=user.role?></td><td><?lsp=app.xssfilter(user.subject or '')?></td><td><form method="post"><input type="hidden" name="csrf" value="<?lsp=page.csrf?>"><input type="hidden" name="action" value="delete"><input type="hidden" name="email" value="<?lsp=app.xssfilter(user.name)?>"><button class="btn btn-danger">Remove</button></form></td></tr>
<?lsp end ?></tbody></table></div></div>
<div class="card card-body"><h2>Add or update a user</h2><form method="post"><input type="hidden" name="csrf" value="<?lsp=page.csrf?>"><input type="hidden" name="action" value="save">
<div class="form-group"><label for="email">Email</label><input id="email" name="email" type="email" required></div>
<div class="form-group"><label for="role">Role</label><select id="role" name="role"><option value="viewer">Viewer</option><option value="operator">Operator</option><option value="admin">Zone administrator</option></select></div>
<div class="form-group"><label for="password">Password (leave blank to retain the existing password)</label><input id="password" name="password" type="password" minlength="8" maxlength="1024" autocomplete="new-password"></div>
<div class="form-group"><label for="subject">Microsoft Entra user object ID (optional; blank disables SSO for this user)</label><input type="text" id="subject" name="subject" maxlength="36"></div><button class="btn btn-primary">Save user</button></form></div>
<div class="card card-body"><h2>Microsoft Entra sign-in</h2><p>Use a single-tenant Web application with redirect URI <code>https://<?lsp=page.zname?>/sso</code>. Only explicitly added users with matching email and object ID can sign in. Local passwords remain available.</p>
<form method="post"><input type="hidden" name="csrf" value="<?lsp=page.csrf?>"><input type="hidden" name="action" value="sso">
<label><input type="checkbox" name="enabled" value="yes" <?lsp=config.enabled and 'checked' or ''?>> Enable Microsoft Entra sign-in</label>
<div class="form-group"><label for="tenant">Tenant ID</label><input type="text" id="tenant" name="tenant" value="<?lsp=app.xssfilter(config.tenant or '')?>" maxlength="36"></div>
<div class="form-group"><label for="client_id">Application (client) ID</label><input type="text" id="client_id" name="client_id" value="<?lsp=app.xssfilter(config.client_id or '')?>" maxlength="36"></div>
<div class="form-group"><label for="secret">Client secret Value (leave blank to retain the saved secret)</label><input id="secret" name="secret" type="password" maxlength="512" autocomplete="new-password"></div>
<div class="form-group"><label for="expires">Client secret expiration</label><input id="expires" name="expires" type="date" value="<?lsp=app.xssfilter(config.client_secret_expires or '')?>"></div><button class="btn btn-primary">Save sign-in settings</button></form></div>
