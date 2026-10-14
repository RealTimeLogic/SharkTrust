(function () {
  "use strict";
  let sequence = 0;
  let activeButton;
  let activeDetails;
  const csrf = document.querySelector('meta[name="csrf-token"]').content;
  function collapse() {
    if (activeButton) {
      activeButton.setAttribute("aria-expanded", "false");
      activeButton.querySelector("span").className = "arrow darrow";
    }
    if (activeDetails) activeDetails.remove();
    activeButton = activeDetails = null;
  }
  document.querySelectorAll(".devtab .info").forEach(function (button) {
    button.addEventListener("click", async function () {
      const ticket = ++sequence;
      const same = button === activeButton;
      collapse();
      if (same) return;
      activeButton = button;
      const row = button.closest("tr");
      const name = row.querySelector(".name").textContent;
      try {
        const response = await fetch("/rpc/details.lsp?name=" + encodeURIComponent(name));
        if (!response.ok) throw new Error("Unable to load device details.");
        const data = await response.json();
        if (ticket !== sequence) return;
        const details = document.createElement("tr");
        details.className = "device-details";
        const cell = document.createElement("td");
        cell.colSpan = 3;
        const table = document.createElement("table");
        table.className = "table";
        [
          ["Last access", new Date(data.atime * 1000).toLocaleString()],
          ["Certificate expires", data.exptime ? new Date(data.exptime * 1000).toLocaleString() : "Not issued"],
          ["Details", data.info || "Not provided"]
        ].forEach(function (values) {
          const entry = table.insertRow();
          values.forEach(function (value) { entry.insertCell().textContent = value; });
        });
        cell.appendChild(table);
        if (data.canrem) {
          const remove = document.createElement("button");
          remove.className = "btn btn-danger";
          remove.type = "button";
          remove.textContent = "Remove device";
          remove.addEventListener("click", async function () {
            if (!window.confirm("Remove " + name + " and its certificate?")) return;
            remove.disabled = true;
            try {
              const result = await fetch("/rpc/deletedevice.lsp", {
                method: "POST", body: new URLSearchParams({ name: name, csrf: csrf })
              });
              if (!result.ok || !(await result.json()).ok) throw new Error("Unable to remove device.");
              ++sequence;
              collapse();
              row.remove();
              portalToast.success("Device removed.");
            } catch (error) { portalToast.error(error.message); remove.disabled = false; }
          });
          cell.appendChild(remove);
        }
        details.appendChild(cell);
        row.after(details);
        activeDetails = details;
        button.setAttribute("aria-expanded", "true");
        button.querySelector("span").className = "arrow uarrow";
      } catch (error) { if (ticket === sequence) { collapse(); portalToast.error(error.message); } }
    });
  });
  document.querySelectorAll('input[name="password2"]').forEach(function (confirm) {
    const password = confirm.form.querySelector('input[name="password"]');
    function validate() { confirm.setCustomValidity(confirm.value === password.value ? "" : "Passwords must match."); }
    confirm.addEventListener("input", validate);
    password.addEventListener("input", validate);
  });
}());
