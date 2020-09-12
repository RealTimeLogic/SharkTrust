<?lsp
local wanT = ((app.rwWanT(page.zkey) or {})[app.peername(request)] or {})
if not next(wanT) then
   response:write'<h1>No Devices</h1><p>No devices are registered in your location.</p>'
   return
end
?>
<h1>Local Devices</h1>

<table class="table table-striped table-bordered">
  <thead class="thead-dark"><th>Name</th><th>IP Addr</th><th>Details</th></thead>
  <tbody class="devtab">
<?lsp
   local zname=page.zname
   for dname,ip in pairs(wanT) do
      response:write('<tr><td><a class="name" href="https://',dname,'.',zname,'">',dname,
                     '</a></td><td>',ip,'</td><td class="info"><div class="arrow darrow"></div></td></tr>')
   end
?>
  </tbody>
</table>


