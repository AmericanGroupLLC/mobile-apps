// Tiny enhancement: stamp the copyright year so the site never feels stale.
(function () {
  var el = document.getElementById("copyright-year");
  if (el) el.textContent = String(new Date().getFullYear());
})();
