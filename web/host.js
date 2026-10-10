// The browser host handles platform effects. MoonBit renders pages and decides UI state.
import { mountMotion } from './motion.js';
const root = document.documentElement;
const app = document.getElementById('app');
const reducedMotion = matchMedia('(prefers-reduced-motion: reduce)');
let renderer;
let siteJson;
let resumeJson;
let route = location.pathname;
let menuOpen = false;
let disposeMotion = () => {};
let navigating = false;

async function fetchText(url) {
  const response = await fetch(url);
  if (!response.ok) throw new Error(`Unable to load ${url}: ${response.status}`);
  return response.text();
}

async function loadRenderer() {
  const response = await fetch('/runtime/portfolio.wasm');
  if (!response.ok) throw new Error(`Unable to load MoonBit Wasm: ${response.status}`);
  const bytes = await response.arrayBuffer();
  try {
    const { instance } = await WebAssembly.instantiate(bytes, {}, { builtins: ['js-string'], importedStringConstants: '_' });
    return { api: instance.exports, target: 'wasm-gc' };
  } catch (wasmError) {
    const fallbackModuleUrl = '/runtime/portfolio.js';
    const fallback = await import(/* @vite-ignore */ fallbackModuleUrl);
    console.info('Using the MoonBit JavaScript backend because Wasm GC initialization failed.', wasmError);
    return { api: fallback, target: 'js' };
  }
}

function syncControls() {
  const theme = root.dataset.theme || 'light';
  const button = app.querySelector('[data-action="theme"]');
  if (button) {
    button.setAttribute('aria-label', `Switch to ${theme === 'dark' ? 'light' : 'dark'} theme`);
    button.querySelectorAll('.theme-symbol').forEach(icon => {
      icon.hidden = icon.classList.contains('theme-symbol-sun') !== (theme === 'dark');
    });
  }
  app.querySelector('#primary-navigation')?.classList.toggle('is-open', menuOpen);
  const menuButton = app.querySelector('[data-action="menu"]');
  menuButton?.setAttribute('aria-expanded', String(menuOpen));
  menuButton?.querySelectorAll('[data-state]').forEach(icon => { icon.hidden = icon.dataset.state !== (menuOpen ? 'open' : 'closed'); });
}

function setMenu(open, focus = false) {
  menuOpen = open;
  syncControls();
  if (focus) app.querySelector(open ? '#primary-navigation a' : '[data-action="menu"]')?.focus();
}

function metadata(path) {
  const meta = JSON.parse(renderer.page_metadata(path, siteJson, resumeJson));
  document.title = meta.title;
  const values = { description: meta.description, 'og:title': meta.title, 'og:description': meta.description, 'og:url': meta.canonical, 'og:image': meta.image, 'og:image:secure_url': meta.image, 'twitter:image': meta.image };
  for (const [key, value] of Object.entries(values)) {
    document.querySelector(`meta[name="${key}"], meta[property="${key}"]`)?.setAttribute('content', value);
  }
  document.querySelector('link[rel="canonical"]')?.setAttribute('href', meta.canonical);
}

function saveScroll() {
  history.replaceState({ ...history.state, portfolio: true, scroll: [scrollX, scrollY] }, '', location.href);
}

function scrollToDestination(url, savedScroll) {
  if (savedScroll) return window.scrollTo({ left: savedScroll[0], top: savedScroll[1], behavior: 'instant' });
  if (url.hash) {
    let id;
    try { id = decodeURIComponent(url.hash.slice(1)); } catch { id = url.hash.slice(1); }
    const target = document.getElementById(id);
    if (target) {
      target.scrollIntoView({ behavior: 'instant' });
      if (id === 'main-content') target.focus({ preventScroll: true });
      return;
    }
  }
  window.scrollTo({ left: 0, top: 0, behavior: 'instant' });
}

async function showPage(url, savedScroll, focus = true) {
  const changed = url.pathname !== route;
  const previousRoute = route;
  const projectPath = previousRoute === '/' ? url.pathname : url.pathname === '/' ? previousRoute : '';
  const slug = /^\/work\/([^/]+)$/.exec(projectPath)?.[1];
  const setTransitionNames = () => {
    const figure = route === '/'
      ? app.querySelector(`.project-art-${CSS.escape(slug)}`)?.closest('figure')
      : app.querySelector('.case-screenshot');
    const image = figure?.querySelector('.project-image-link img');
    const frame = figure?.querySelector('.project-transition-frame');
    if (image) image.style.viewTransitionName = `project-${slug}-image`;
    if (frame) frame.style.viewTransitionName = `project-${slug}-frame`;
    return image;
  };
  const update = () => {
    if (changed) {
      disposeMotion();
      app.innerHTML = renderer.render_page(url.pathname, siteJson, resumeJson, new Date().getFullYear());
      route = url.pathname;
      menuOpen = false;
      metadata(route);
      syncControls();
    }
    scrollToDestination(url, savedScroll);
    if (changed) disposeMotion = mountMotion(app);
    if (changed && focus && !url.hash) document.getElementById('main-content')?.focus({ preventScroll: true });
  };
  if (changed && slug && document.startViewTransition && !reducedMotion.matches) {
    setTransitionNames();
    const transition = document.startViewTransition(async () => {
      update();
      const image = setTransitionNames();
      if (image) try { await image.decode(); } catch { /* Navigation remains usable when an image fails. */ }
      scrollToDestination(url, savedScroll);
    });
    try { await transition.finished; } catch { /* Superseded transitions have already applied their update. */ }
    // The native transition can adjust the viewport after its update callback.
    // Restore the requested position once its snapshot animation has finished.
    if (location.href === url.href) scrollToDestination(url, savedScroll);
    app.querySelectorAll('[style*="view-transition-name"]').forEach(element => element.style.removeProperty('view-transition-name'));
  } else { update(); }
}

async function navigate(url) {
  if (navigating) return;
  navigating = true;
  try {
    saveScroll();
    history.pushState({ portfolio: true, fromHome: route === '/' && url.pathname.startsWith('/work/') }, '', url.href);
    setMenu(false);
    await showPage(url);
  } finally { navigating = false; }
}

async function initialize() {
  const [runtime, site, resume] = await Promise.all([loadRenderer(), fetchText('/content/site.json'), fetchText('/content/resume.json')]);
  renderer = runtime.api;
  siteJson = site;
  resumeJson = resume;
  history.scrollRestoration = 'manual';
  history.replaceState({ ...history.state, portfolio: true, scroll: [scrollX, scrollY] }, '', location.href);
  syncControls();
  disposeMotion = mountMotion(app);
  document.addEventListener('click', event => {
    const button = event.target.closest('button[data-action]');
    if (button?.dataset.action === 'theme') {
      root.dataset.theme = renderer.toggle_theme(root.dataset.theme || 'light');
      try { localStorage.setItem('portfolio-theme', root.dataset.theme); } catch { /* Theme remains active for this visit. */ }
      syncControls();
      return;
    }
    if (button?.dataset.action === 'menu') return setMenu(Boolean(renderer.toggle_menu(menuOpen)), true);
    const anchor = event.target.closest('a[href]');
    if (!anchor || event.defaultPrevented || event.button !== 0 || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey || anchor.target || anchor.hasAttribute('download')) return;
    const url = new URL(anchor.href);
    if (url.origin !== location.origin || !['http:', 'https:'].includes(url.protocol) || /\.[a-z0-9]+$/i.test(url.pathname)) return;
    if (anchor.dataset.action === 'all-work' && history.state?.fromHome) {
      event.preventDefault(); saveScroll(); history.back(); return;
    }
    event.preventDefault();
    navigate(url).catch(error => { console.error(error); location.assign(url.href); });
  });
  document.addEventListener('keydown', event => {
    if (event.key === 'Escape' && menuOpen) { event.preventDefault(); setMenu(false, true); }
  });
  window.addEventListener('popstate', () => {
    showPage(new URL(location.href), history.state?.scroll).catch(error => { console.error(error); location.reload(); });
  });
  window.addEventListener('pagehide', saveScroll);
  root.dataset.runtime = runtime.target;
}

initialize().catch(error => {
  console.error('MoonBit runtime failed to initialize.', error);
  const notice = document.createElement('p');
  notice.className = 'runtime-notice';
  notice.textContent = 'Interactive controls could not load. The portfolio and links remain available; reload to try again.';
  app.prepend(notice);
  delete root.dataset.js;
});
