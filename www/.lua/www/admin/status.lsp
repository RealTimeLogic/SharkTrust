<div class="card card-body"><h2>Certificate authority</h2><dl><dt>Environment</dt><dd><?lsp=app.ca.production and 'Production' or 'Staging'?></dd><dt>ACME directory</dt><dd><?lsp=app.xssfilter(app.ca.directoryUrl)?></dd></dl><p>Select the directory and environment in <code>mako.conf</code>, then restart the portal. Each combination has a separate certificate store.</p></div>
<div class="card card-body"><h2>Pending operations</h2><div class="table-wrap"><table class="table table-striped table-bordered"><thead><tr><th>Operation</th><th>Target</th><th>Next attempt</th></tr></thead><tbody>
<?lsp
for kind,state in pairs(app.retryStatus) do
   for key,value in pairs(state) do
      local device=kind=='devices' and app.rwDeviceT(key)
      local name=device and device.name or kind=='portal' and key or 'Removed device'
      _emit('<tr><td>Certificate</td><td>',app.xssfilter(name),'</td><td>',os.date('%Y-%m-%d %H:%M:%S',value.at),'</td></tr>')
   end
end
for name in pairs(app.dnsPending) do _emit('<tr><td>DNS reload</td><td>',app.xssfilter(name),'</td><td>Retry within 30 seconds</td></tr>') end
if app.dnsConfigurationPending() then _emit('<tr><td>DNS configuration</td><td>All zones</td><td>Retry within 30 seconds</td></tr>') end
?>
</tbody></table></div></div>
