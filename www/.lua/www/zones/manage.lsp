<?lsp
local wanT = app.rwWanT(page.zkey) or {}
if next(wanT) then
   _emit'<h2>All Registered Devices</h2>'
else
   _emit'<h2>No Devices</h2><p>No registered devices!</p>'
   return
end
for wip, wanT in pairs(wanT) do
?>

<div class="card card-body">
<h2><?lsp=wip?></h2>
<div class="table-wrap"><table class="table device-table table-striped table-bordered">
  <thead class="table-heading"><tr><th>Name</th><th>IP Addr</th><th>Details</th></tr></thead>
  <tbody class="devtab">
<?lsp
   local zname=page.zname
   for dname,ip in pairs(wanT) do
      _emit('<tr><td class="name">',dname,
                     '</td><td>',ip,
                     '</td><td><button type="button" class="info" aria-label="Show device details" aria-expanded="false"><span class="arrow darrow"></span></button></td></tr>')
   end
?>
  </tbody>
</table></div>
</div>
<?lsp end ?>

