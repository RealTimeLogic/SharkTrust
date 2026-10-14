<?lsp
local zname=app.host(request)
if request:method() == "POST" and request:data"terminate" == "yes" then
  app.deleteZone(zname,app.writeRedirect(response,app.serverAddr()))
  return
end
?>
<div class="card card-body">
  <?lsp if app.sensitive.consume(app.sensitiveSession(request,page.zkey),"secret") then ?>
  <div class="alert alert-success" role="alert">Zone Key: <?lsp=page.zkey?></div>
  <?lsp else ?><a class="btn btn-primary" href="/verify?purpose=secret">Verify by email to show zone key</a><?lsp end ?>

  <div class="form-group">&nbsp;</div>
  <form method="post">
<input type="hidden" name="csrf" value="<?lsp=page.csrf?>">
    <div class="form-group">
      <input type="submit" class="btn btn-danger btn-block" id="termbut" value="Terminate Account"/>
      <input type="hidden" id="terminate" name="terminate" value="no"/>
    </div>
  </form>
</div>

<script>
$(function() {
    $("#termbut").click(function(){
        var yes = prompt("Enter 'yes' to terminate your account","no");
        $("#terminate").val(yes);
        return yes == "yes";
    });
});
</script>

