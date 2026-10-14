<?lsp
local session=request:session(true)
local data=request:data()
local preview=session.cleanupPreview
local message
if request:method()=="POST" then
   if data.action=="preview" then
      local days=tonumber(data.days)
      if days and days%1==0 and days>=1 and days<=36500 then
         local cutoff=os.time()-days*86400
         preview={id=ba.b64urlencode(ba.rndbs(24)),zkey=page.zkey,cutoff=cutoff,expires=os.time()+300,
            devices=app.db.inactive(page.zkey,cutoff)}
         session.cleanupPreview=preview
      else message="Choose a whole number of days from 1 to 36500." end
   elseif data.action=="remove" then
      session.cleanupPreview=nil
      if not preview or preview.zkey~=page.zkey or preview.id~=data.preview or preview.expires<=os.time() or data.acknowledge~="yes" then
         return response:senderror(409)
      end
      local keys={}
      for _,device in ipairs(preview.devices) do keys[#keys+1]=device.dkey end
      local done=app.deferred(response,"/cleanup")
      -- Re-check activity in the transaction. Devices seen since preview survive.
      app.deleteDevices(page.zname,page.zkey,keys,preview.cutoff,function(ok,count)
         done(ok and 303 or 500,ok and nil or {error="Cleanup failed"})
      end)
      return
   end
end
if preview and (preview.expires<=os.time() or preview.zkey~=page.zkey) then preview=nil end
?>
<div class="card card-body"><p>Preview devices that have not contacted the portal recently. No device is removed automatically. Devices that reconnect after this preview are retained.</p>
<?lsp if message then ?><p class="alert alert-warning"><?lsp=message?></p><?lsp end ?>
<form method="post"><input type="hidden" name="csrf" value="<?lsp=page.csrf?>"><input type="hidden" name="action" value="preview">
<div class="form-group"><label for="days">Days inactive</label><input id="days" name="days" type="number" class="form-control" min="1" max="36500" value="90" required></div><button class="btn btn-primary">Preview devices</button></form></div>
<?lsp if preview then ?>
<div class="card card-body"><p><?lsp=#preview.devices?> devices eligible. This preview expires in five minutes.</p>
<div class="table-wrap"><table class="table table-striped table-bordered"><thead><tr><th>Device</th><th>Address</th><th>Last contact</th></tr></thead><tbody>
<?lsp for _,d in ipairs(preview.devices) do ?><tr><td><?lsp=app.xssfilter(d.name)?></td><td><?lsp=app.xssfilter(d.ip)?></td><td><?lsp=os.date("%Y-%m-%d %H:%M",d.atime)?></td></tr><?lsp end ?>
</tbody></table></div>
<?lsp if #preview.devices>0 then ?>
<form method="post"><input type="hidden" name="csrf" value="<?lsp=page.csrf?>"><input type="hidden" name="action" value="remove"><input type="hidden" name="preview" value="<?lsp=preview.id?>">
<label><input type="checkbox" name="acknowledge" value="yes" required> Remove the listed devices and revoke their credentials.</label><p><button class="btn btn-danger">Remove previewed devices</button></p></form>
<?lsp end ?></div><?lsp end ?>
