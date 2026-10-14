<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="csrf-token" content="<?lsp=page.csrf or ''?>">
  <title><?lsp=app.xssfilter(page.title)?> | SharkTrust</title>
  <link rel="icon" href="/favicon.ico">
  <link rel="stylesheet" href="/assets/style.css">
  <script src="/rtl/jquery.js"></script>
</head>
<body>
<div id="layout" class="app-shell">
  <button id="menuLink" class="menu-link" type="button" aria-label="Toggle navigation" aria-controls="menu" aria-expanded="false"><span></span></button>
  <aside id="menu" class="side-nav" aria-label="Primary navigation">
    <div class="nav-inner">
      <a class="nav-brand" href="https://realtimelogic.com/services/SharkTrust/">
        <span class="brand-mark" aria-hidden="true">S</span>
        <span class="brand-copy"><strong>SharkTrust</strong><small>Certificate services portal</small></span>
      </a>
      <nav><ul class="nav-list">
<?lsp
for _,item in ipairs(page.menuT or {}) do
   if ((page.authenticated and item.link~="login") or (not page.authenticated and item.visible)) and
      (not item.role or app.authorized(request,page.zkey,item.role)) then
      local active=item.link==page.link
      response:write('<li class="nav-item"><a class="nav-link',active and ' is-active' or '',
         '" href="/',item.link=="." and "" or item.link,'"',active and ' aria-current="page"' or '',
         '>',app.xssfilter(item.name),'</a></li>')
   end
end
?>
      </ul></nav>
      <div class="nav-account">
<?lsp if page.authenticated then local session=request:session() ?>
        <span class="account-name"><?lsp=app.xssfilter(session.name or "Administrator")?></span>
        <form method="post" action="/logout.lsp"><input type="hidden" name="csrf" value="<?lsp=page.csrf?>"><button class="text-button" type="submit">Sign out</button></form>
<?lsp else ?>
        <span class="account-name">Guest access</span><a href="/login">Sign in</a>
<?lsp end ?>
      </div>
    </div>
  </aside>
  <main id="main" class="main-pane">
    <header class="page-header">
      <div><p class="eyebrow">SharkTrust portal</p><h1><?lsp=app.xssfilter(page.title)?></h1></div>
      <div class="page-meta"><nav class="breadcrumbs" aria-label="Breadcrumb"><a href="/">Home</a><span aria-hidden="true">/</span><span aria-current="page"><?lsp=app.xssfilter(page.title)?></span></nav>
        <span class="page-user"><?lsp=app.xssfilter(page.zname or app.settingsT.dn)?></span>
      </div>
    </header>
    <section class="content page-content"><?lsp page.lsp(_ENV,path,io,page,app) ?></section>
    <footer class="site-footer"><span>&copy; Real Time Logic</span><a href="https://realtimelogic.com/">realtimelogic.com</a></footer>
  </main>
</div>
<div id="toastRegion" class="toast-region" aria-live="polite" aria-atomic="true"></div>
<script src="/assets/dashboard.js"></script>
<script src="/assets/sharktrust.js"></script>
</body>
</html>
