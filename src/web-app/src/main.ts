// Theme Management
const THEME_KEY = 'ravintio-theme';

const setTheme = (theme: 'light' | 'dark') => {
  document.documentElement.setAttribute('data-theme', theme);
  localStorage.setItem(THEME_KEY, theme);
};

const getPreferredTheme = () => {
  const saved = localStorage.getItem(THEME_KEY);
  if (saved) return saved as 'light' | 'dark';
  return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
};

// Initialize Theme
setTheme(getPreferredTheme());

// Page list disclosure: closed on a phone, open as a sidebar on desktop (ADR-002).
// Module scripts run once the document is parsed, so the element exists here.
const pageList = document.querySelector<HTMLDetailsElement>('.doc-sections__disclosure');
if (pageList) {
  const mobile = window.matchMedia('(max-width: 900px)');
  pageList.open = !mobile.matches;
  mobile.addEventListener('change', e => { pageList.open = !e.matches; });
}

// Mermaid loads only on pages with a diagram, to keep other pages light (NFR-002).
const renderDiagrams = async () => {
  if (!document.querySelector('pre.mermaid')) return;
  const { default: mermaid } = await import('mermaid');
  mermaid.initialize({
    startOnLoad: false,
    theme: getPreferredTheme() === 'dark' ? 'dark' : 'default',
    securityLevel: 'antiscript',
  });
  await mermaid.run();
};

const scrollToHash = () => {
  if (!window.location.hash) return;
  try {
    const el = document.querySelector(window.location.hash);
    if (el) el.scrollIntoView({ behavior: 'instant' });
  } catch {}
};

document.addEventListener('DOMContentLoaded', () => {
  // Re-scroll after diagrams render so layout shift doesn't lose position
  renderDiagrams().then(scrollToHash);

  // Theme Toggle Button Logic
  const toggleBtn = document.getElementById('theme-toggle');
  if (toggleBtn) {
    toggleBtn.addEventListener('click', () => {
      const current = document.documentElement.getAttribute('data-theme');
      setTheme(current === 'light' ? 'dark' : 'light');
      // Mermaid draws SVGs once, so a diagram page reloads to redraw in the new theme
      if (document.querySelector('pre.mermaid')) location.reload();
    });
  }

  // Smooth Scroll for anchor links
  document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (this: HTMLAnchorElement, e) {
      const targetId = this.getAttribute('href');
      if (!targetId || targetId === '#') return;
      const targetElement = document.querySelector(targetId);
      if (targetElement) {
        e.preventDefault();
        targetElement.scrollIntoView({ behavior: 'smooth' });
      }
    });
  });

  // Reveal animations on scroll
  const revealElements = document.querySelectorAll('.reveal');
  const revealOnScroll = () => {
    const windowHeight = window.innerHeight;
    const elementVisible = 100;
    revealElements.forEach(el => {
      const elementTop = el.getBoundingClientRect().top;
      if (elementTop < windowHeight - elementVisible) {
        el.classList.add('fade-in-up');
        el.classList.remove('reveal'); // only animate once
      }
    });
  };
  window.addEventListener('scroll', revealOnScroll);
  revealOnScroll();

  // --- MOBILE NAV TOGGLE LOGIC ---
  const navLinks = document.querySelector('.nav-links');
  document.querySelectorAll<HTMLButtonElement>('.hamburger-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      if (!navLinks) return;
      const open = navLinks.classList.toggle('show');
      btn.setAttribute('aria-expanded', String(open));
    });
  });
});
