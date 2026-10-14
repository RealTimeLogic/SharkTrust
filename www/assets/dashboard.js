(function (window, document) {
  "use strict";

  const layout = document.getElementById("layout");
  const menu = document.getElementById("menu");
  const menuLink = document.getElementById("menuLink");
  const toastRegion = document.getElementById("toastRegion");

  function setMenu(open) {
    layout.classList.toggle("active", open);
    menu.classList.toggle("active", open);
    menuLink.classList.toggle("active", open);
    menuLink.setAttribute("aria-expanded", String(open));
  }

  menuLink.addEventListener("click", function () {
    setMenu(!menu.classList.contains("active"));
  });

  layout.addEventListener("click", function (event) {
    const title = event.target.closest && event.target.closest(".nav-group-title");
    if (title && title.tagName === "SPAN") {
      title.closest(".nav-group").classList.toggle("is-open");
      return;
    }
    if (menu.classList.contains("active") && !menu.contains(event.target) && !menuLink.contains(event.target)) {
      setMenu(false);
    }
  });

  document.addEventListener("keydown", function (event) {
    if (event.key === "Escape" && menu.classList.contains("active")) {
      setMenu(false);
      menuLink.focus();
    }
  });

  function showToast(message, kind) {
    const toast = document.createElement("div");
    const close = document.createElement("button");
    const heading = document.createElement("strong");
    const body = document.createElement("span");

    toast.className = "portal-toast portal-toast-" + kind;
    toast.setAttribute("role", kind === "error" ? "alert" : "status");
    heading.textContent = kind === "error" ? "Failed" : kind.charAt(0).toUpperCase() + kind.slice(1);
    body.textContent = String(message);
    close.type = "button";
    close.className = "toast-close";
    close.setAttribute("aria-label", "Dismiss notification");
    close.textContent = "\u00d7";
    close.addEventListener("click", function () { toast.remove(); });

    toast.append(heading, body, close);
    toastRegion.appendChild(toast);
    window.setTimeout(function () { toast.remove(); }, 6000);
  }

  window.portalToast = {
    success: function (message) { showToast(message, "success"); },
    warning: function (message) { showToast(message, "warning"); },
    error: function (message) { showToast(message, "error"); },
    info: function (message) { showToast(message, "info"); }
  };
}(this, this.document));
