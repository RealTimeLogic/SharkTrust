<?lsp
?>
<h1>Manage Zones</h1>

<?lsp
local zonesT = app.rcZonesT()
if not next(zonesT) then response:write'<p>No registered zones!</p>' return end
?>

<table class="table table-striped table-bordered">
  <thead class="thead-dark"><th>Domain</th><th>Zone Name</th></thead>
  <tbody class="devtab">
<?lsp
   local zname=page.zname
   for zname,zkey in pairs(zonesT) do
      response:write('<tr><td><a href="https://',zname,'">https://',zname,
                     '</a></td><td><a href="zone?name=',zname,'">',zname,
                     '</a></td></tr>')
   end
?>
  </tbody>
</table>



