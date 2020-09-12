<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
    <title><?lsp=page.title?></title>
    <!-- Bootstrap core CSS -->
    <link href="https://stackpath.bootstrapcdn.com/bootstrap/4.4.1/css/bootstrap.min.css" rel="stylesheet">
    <link href="assets/style.css" rel="stylesheet">
    <script src="https://code.jquery.com/jquery-3.4.1.min.js"></script>
  </head>
  <body>
    <!-- Navigation -->
    <nav class="navbar navbar-expand-lg navbar-dark bg-dark static-top">
      <div class="container">
        <a class="navbar-brand" href="https://realtimelogic.com/services/SharkTrust/">
          <img style="max-width:250px" src="https://realtimelogic.com/GZ/images/icons/RealTimeLogicInv.svg" alt="SharkTrust"/>
        </a>
        <button class="navbar-toggler" type="button" data-toggle="collapse" data-target="#navbarResponsive" aria-controls="navbarResponsive" aria-expanded="false" aria-label="Toggle navigation">
          <span class="navbar-toggler-icon"></span>
        </button>
        <div class="collapse navbar-collapse" id="navbarResponsive">
          <ul class="navbar-nav ml-auto">
<?lsp -- Render the top menu
   local link = page.link
   local auth=page.authenticated
   if page.menuT then
      for _,miT in pairs(page.menuT) do
         if (auth and miT.link ~= 'login') or (not auth and miT.visible) then
            response:write('<li class="nav-item', miT.link==link and ' active"' or '"' ,
                           '><a class="nav-link" href="',miT.link,'">',miT.name,'</a></li>')
         end
      end
   end
?>
          </ul>
        </div>
      </div>
    </nav>
    <!-- Page Content -->
    <div class="container">
      <div class="row">
        <div class="col-lg-12">
      
           <?lsp page.lsp(_ENV,path,io,page,app) ?>
        </div>
      </div>
    </div>
    <!-- Bootstrap core JavaScript -->
    <script src="https://stackpath.bootstrapcdn.com/bootstrap/4.4.1/js/bootstrap.min.js"></script>
    <script src="assets/sharktrust.js"></script>
  </body>
</html>
