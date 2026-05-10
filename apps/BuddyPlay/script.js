// BuddyPlay marketing site — minimal progressive enhancement.
// Smooth-scroll for in-page anchors; respect prefers-reduced-motion.

(function () {
  "use strict";

  var reduce =
    window.matchMedia &&
    window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  document.querySelectorAll('a[href^="#"]').forEach(function (a) {
    a.addEventListener("click", function (e) {
      var id = a.getAttribute("href");
      if (id.length < 2) return;
      var el = document.querySelector(id);
      if (!el) return;
      e.preventDefault();
      el.scrollIntoView({
        behavior: reduce ? "auto" : "smooth",
        block: "start",
      });
      // Update URL for shareability without a jump.
      if (history && history.pushState) {
        history.pushState(null, "", id);
      }
    });
  });
})();
