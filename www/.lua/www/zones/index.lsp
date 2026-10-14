<?lsp
local wanT = ((app.rwWanT(page.zkey) or {})[app.peername(request)] or {})
if not next(wanT) then
   _emit'<h2>No Devices</h2><p>No devices are registered in your location.</p>'
   return
end
?>
<h2>Local Devices</h2>

<div class="table-wrap"><table class="table device-table table-striped table-bordered">
  <thead class="table-heading"><tr><th>Name</th><th>IP Addr</th><th>Details</th></tr></thead>
  <tbody class="devtab">
<?lsp
   local zname=page.zname
   for dname,ip in pairs(wanT) do
      _emit('<tr><td><a class="name" href="https://',dname,'.',zname,'">',dname,
                     '</a></td><td>',ip,'</td><td><button type="button" class="info" aria-label="Show device details" aria-expanded="false"><span class="arrow darrow"></span></button></td></tr>')
   end
?>
  </tbody>
</table></div>


