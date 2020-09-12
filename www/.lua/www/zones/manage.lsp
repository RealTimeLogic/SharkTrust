<?lsp
local wanT = app.rwWanT(page.zkey) or {}
if next(wanT) then
   response:write'<h1>All Registered Devices</h1>'
else
   response:write'<h1>No Devices</h1><p>No registered devices!</p>'
   return
end
for wip, wanT in pairs(wanT) do
?>

<div class="card card-body bg-light">
<h2><?lsp=wip?></h2>
<table class="table table-striped table-bordered">
  <thead class="thead-dark"><th>Name</th><th>IP Addr</th><th>Details</th></thead>
  <tbody class="devtab">
<?lsp
   local zname=page.zname
   for dname,ip in pairs(wanT) do
      response:write('<tr><td class="name">',dname,
                     '</td><td>',ip,
                     '</td><td class="info"><div class="arrow darrow"></div></td></tr>')
   end
?>
  </tbody>
</table>
</div>
<?lsp end ?>

