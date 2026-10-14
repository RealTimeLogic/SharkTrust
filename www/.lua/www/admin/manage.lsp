<?lsp
?>

<?lsp
local zonesT = app.rcZonesT()
if not next(zonesT) then _emit'<p>No registered zones!</p>' return end
?>

<div class="table-wrap"><table class="table table-striped table-bordered">
  <thead class="table-heading"><tr><th>Domain</th><th>Zone Name</th></tr></thead>
  <tbody class="devtab">
<?lsp
   local zname=page.zname
   for zname,zkey in pairs(zonesT) do
      _emit('<tr><td><a href="https://',zname,'">https://',zname,
                     '</a></td><td><a href="zone?name=',zname,'">',zname,
                     '</a></td></tr>')
   end
?>
  </tbody>
</table></div>



