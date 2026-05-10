// ============ Year ============
document.getElementById('year').textContent = new Date().getFullYear();

// ============ Navbar scroll state ============
const navbar = document.getElementById('navbar');
window.addEventListener('scroll', () => {
  navbar.classList.toggle('scrolled', window.scrollY > 8);
});

// ============ Mobile menu ============
const menuToggle = document.getElementById('menuToggle');
menuToggle.addEventListener('click', () => {
  const open = navbar.classList.toggle('open');
  menuToggle.setAttribute('aria-expanded', open);
});
document.querySelectorAll('.nav-links a').forEach((link) => {
  link.addEventListener('click', () => {
    navbar.classList.remove('open');
    menuToggle.setAttribute('aria-expanded', 'false');
  });
});

// ============ Tabs (App categories) ============
const tabs = document.querySelectorAll('.tab');
const appCards = document.querySelectorAll('.app-card');

tabs.forEach((tab) => {
  tab.addEventListener('click', () => {
    tabs.forEach((t) => {
      t.classList.remove('active');
      t.setAttribute('aria-selected', 'false');
    });
    tab.classList.add('active');
    tab.setAttribute('aria-selected', 'true');

    const filter = tab.dataset.filter;
    appCards.forEach((card) => {
      if (filter === 'all' || card.dataset.category === filter) {
        card.classList.remove('hidden');
      } else {
        card.classList.add('hidden');
      }
    });
  });
});

// ============ Fade-in on scroll ============
const animatedEls = document.querySelectorAll(
  '.card, .feature, .issue-card, .org-card, .app-card, .reco-card, .stat'
);
animatedEls.forEach((el) => el.classList.add('fade-in'));

const observer = new IntersectionObserver(
  (entries) => {
    entries.forEach((entry) => {
      if (entry.isIntersecting) {
        entry.target.classList.add('visible');
        observer.unobserve(entry.target);
      }
    });
  },
  { threshold: 0.12 }
);
animatedEls.forEach((el) => observer.observe(el));
