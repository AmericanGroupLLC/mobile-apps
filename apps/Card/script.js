// Card marketing site — minimal client-side: live clock + footer year.
(function () {
  'use strict';

  // ── Live hero clock (the "thought-to-stored" reminder ticks here) ─
  const heroTime = document.getElementById('hero-time');
  if (heroTime) {
    const tick = () => {
      const now = new Date();
      const pad = (n) => String(n).padStart(2, '0');
      heroTime.textContent =
        pad(now.getHours()) + ':' +
        pad(now.getMinutes()) + ':' +
        pad(now.getSeconds());
    };
    tick();
    setInterval(tick, 1000);
  }

  // ── Footer copyright year ───────────────────────────────────────
  const yearEl = document.getElementById('copyright-year');
  if (yearEl) yearEl.textContent = String(new Date().getFullYear());

  // ── Smooth in-page anchor focus (a11y) ──────────────────────────
  document.querySelectorAll('a[href^="#"]').forEach((link) => {
    link.addEventListener('click', (event) => {
      const id = link.getAttribute('href').slice(1);
      const target = id && document.getElementById(id);
      if (!target) return;
      // Native scroll-behavior: smooth handles the animation; just move focus.
      setTimeout(() => target.setAttribute('tabindex', '-1'), 0);
      setTimeout(() => target.focus({ preventScroll: true }), 350);
    });
  });
})();
