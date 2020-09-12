<?lsp
local zname=request:header"host"
if request:method() == "POST" and request:data"terminate" == "yes" then
  app.deleteZone(zname)
  response:sendredirect("https://"..app.settingsT.dn)
end
?>
<h1>Settings</h1>
<div class="card card-body bg-light">
  <div class="alert alert-success" role="alert">Zone Key: <?lsp=app.rcZonesT()[zname]?></div>

  <div class="form-group">&nbsp;</div>
  <form method="post">
    <div class="form-group">
      <input type="submit" class="btn btn-primary btn-block" id="termbut" value="Terminate Account"/>
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

