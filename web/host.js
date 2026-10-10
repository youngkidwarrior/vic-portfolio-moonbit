// The browser host handles platform effects. MoonBit renders pages and decides UI state.
const root = document.documentElement;
const app = document.getElementById('app');
const reducedMotion = matchMedia('(prefers-reduced-motion: reduce)');
const finePointer = matchMedia('(pointer: fine)');
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
    button.innerHTML = theme === 'dark'
      ? '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><circle cx="12" cy="12" r="4"/><path d="M12 1v3m0 16v3M1 12h3m16 0h3M4.2 4.2l2.1 2.1m11.4 11.4 2.1 2.1M4.2 19.8l2.1-2.1M17.7 6.3l2.1-2.1"/></svg>'
      : '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M20.9 13A9 9 0 0 1 11 3.1 9 9 0 1 0 20.9 13Z"/></svg>';
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
  const update = () => {
    if (changed) {
      disposeMotion();
      app.innerHTML = renderer.render_page(url.pathname, siteJson, resumeJson, new Date().getFullYear());
      route = url.pathname;
      menuOpen = false;
      metadata(route);
      syncControls();
      disposeMotion = mountMotion();
    }
    scrollToDestination(url, savedScroll);
    if (changed && focus && !url.hash) document.getElementById('main-content')?.focus({ preventScroll: true });
  };
  if (changed && document.startViewTransition && !reducedMotion.matches) {
    const transition = document.startViewTransition(update);
    try { await transition.finished; } catch { /* Superseded transitions have already applied their update. */ }
    // The native transition can adjust the viewport after its update callback.
    // Restore the requested position once its snapshot animation has finished.
    if (location.href === url.href) scrollToDestination(url, savedScroll);
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

function mountMotion() {
  const animations = new Set();
  const listeners = [];
  const track = animation => {
    animations.add(animation);
    animation.finished.finally(() => animations.delete(animation)).catch(() => {});
  };
  const observer = new IntersectionObserver(entries => {
    for (const entry of entries) {
      if (!entry.isIntersecting) continue;
      observer.unobserve(entry.target);
      if (!reducedMotion.matches) track(entry.target.animate(
        [{ transform: 'translateY(22px)' }, { transform: 'none' }],
        { duration: 850, easing: 'cubic-bezier(.22,1,.36,1)' },
      ));
    }
  }, { threshold: 0.1 });
  app.querySelectorAll('[data-reveal]').forEach(element => observer.observe(element));
  const artObserver = new IntersectionObserver(entries => {
    for (const entry of entries) {
      if (!entry.isIntersecting) continue;
      artObserver.unobserve(entry.target);
      if (reducedMotion.matches) continue;
      const hero = entry.target.dataset.artwork === 'hero';
      const layers = [...entry.target.querySelectorAll(hero ? '.convergence-band' : '.project-art-slice')];
      layers.forEach((layer, index) => {
        const vertical = ['shenanigan', 'open-source'].includes(entry.target.dataset.artwork);
        const offset = hero ? -130 : (index % 2 ? 64 : -72);
        const transform = vertical ? `translateY(${64 + index * 18}px)` : `translateX(${offset}px)`;
        track(layer.animate([{ transform, opacity: 0.15 }, { transform: 'none', opacity: 1 }], {
          duration: hero ? 2100 : 1900, delay: 100 + index * 230, easing: 'cubic-bezier(.32,.02,.2,1)',
        }));
      });
    }
  }, { threshold: 0.05 });
  app.querySelectorAll('[data-artwork]').forEach(art => artObserver.observe(art));
  for (const surface of app.querySelectorAll('[data-pointer]')) {
    const layers = [...surface.querySelectorAll('.portrait-ink, .project-art-pointer')];
    const reset = () => layers.forEach(layer => layer.style.removeProperty('transform'));
    const move = event => {
      if (reducedMotion.matches || !finePointer.matches || event.pointerType === 'touch') return;
      const box = surface.getBoundingClientRect();
      const x = Math.max(-1, Math.min(1, (event.clientX - box.left) / box.width * 2 - 1));
      const y = Math.max(-1, Math.min(1, (event.clientY - box.top) / box.height * 2 - 1));
      layers.forEach((layer, index) => { layer.style.transform = `translate(${x * (index === 1 ? -12 : 10)}px, ${y * 7}px)`; });
    };
    surface.addEventListener('pointermove', move);
    surface.addEventListener('pointerleave', reset);
    surface.addEventListener('pointercancel', reset);
    listeners.push(() => {
      surface.removeEventListener('pointermove', move);
      surface.removeEventListener('pointerleave', reset);
      surface.removeEventListener('pointercancel', reset);
      reset();
    });
  }
  const stop = () => {
    animations.forEach(animation => animation.cancel());
    animations.clear();
    app.querySelectorAll('.portrait-ink, .project-art-pointer').forEach(layer => layer.style.removeProperty('transform'));
  };
  const preferenceChanged = () => { if (reducedMotion.matches) stop(); };
  reducedMotion.addEventListener('change', preferenceChanged);
  return () => {
    stop(); observer.disconnect(); artObserver.disconnect(); listeners.forEach(dispose => dispose());
    reducedMotion.removeEventListener('change', preferenceChanged);
  };
}

async function initialize() {
  const [runtime, site, resume] = await Promise.all([loadRenderer(), fetchText('/content/site.json'), fetchText('/content/resume.json')]);
  renderer = runtime.api;
  siteJson = site;
  resumeJson = resume;
  history.scrollRestoration = 'manual';
  history.replaceState({ ...history.state, portfolio: true, scroll: [scrollX, scrollY] }, '', location.href);
  syncControls();
  disposeMotion = mountMotion();
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
});
