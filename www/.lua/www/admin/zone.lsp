<?lsp

local data=request:data()

local zname=data.name
local zkey=app.rcZonesT()[zname]
if not zkey then response:sendredirect"manage" end

if request:method() == "POST" and data.terminate == "yes" then
  app.deleteZone(zname)
  response:sendredirect"manage"
end

local zoneT=app.rwZoneT(zkey)

local dCount=0
for _ in pairs(zoneT.devices) do dCount = dCount + 1 end
?>
<h1>Zone Information</h1>
<div class="card card-body bg-light">
  <div class="alert alert-success" role="alert">
   <table>
   <tr><td>Domain:</td><td><?lsp=string.format("<a href='https://%s'>https://%s</a>",zname,zname)?></td></tr>
   <tr><td>Zone Key:</td><td><?lsp=zkey?></td></tr>
   <tr><td>Owner:</td><td><?lsp=zoneT.uname?></td></tr>
   <tr><td>Registered:</td><td><?lsp=os.date("%c",zoneT.rtime)?></td></tr>
   <tr><td>Devices:</td><td><?lsp=dCount?></td></tr>
   </table>
   </div>
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

