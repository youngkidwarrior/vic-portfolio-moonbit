// Native equivalents of the original portfolio's entrance and pointer motion.
const editorialEase = 'cubic-bezier(.22,1,.36,1)';
const inkEase = 'cubic-bezier(.32,.02,.2,1)';
const sequences = {
  send: [[-72, 0, 1, 100, 2100], [64, 0, 1, 350, 2100], [-88, 0, 1, 600, 2100]],
  shenanigan: [[0, 64, 1, 100, 1900], [0, 82, 1, 400, 1900], [0, 100, 1, 700, 1900]],
  brightid: [[-68, 0, 1, 100, 2200], [0, 46, 1, 300, 2200], [68, 0, 1, 500, 2200]],
  'open-source': [[0, -42, 1.16, 100, 2200], [-64, 0, 1.16, 350, 2200], [64, 0, 1.16, 600, 2200]],
};
const clamp = value => Math.max(0, Math.min(1, value));

export function mountMotion(app) {
  const reduced = matchMedia('(prefers-reduced-motion: reduce)');
  const fine = matchMedia('(hover: hover) and (pointer: fine)');
  const played = new WeakSet();
  let teardown = () => {};
  const start = () => {
    if (reduced.matches) return;
    const animations = new Set();
    const disposals = [];
    const styled = new Set();
    let disposed = false;
    const style = (element, property, value) => { styled.add(element); element.style[property] = value; };
    const clear = element => { element.style.removeProperty('opacity'); element.style.removeProperty('transform'); };
    const animate = (element, frames, options, finish = () => {}) => {
      const animation = element.animate(frames, { fill: 'both', ...options });
      animations.add(animation);
      animation.finished.then(() => {
        animations.delete(animation);
        finish();
        animation.cancel();
      }, () => animations.delete(animation));
    };
    const listen = (target, event, callback, options) => {
      target.addEventListener(event, callback, options);
      disposals.push(() => target.removeEventListener(event, callback, options));
    };

    app.querySelectorAll('[data-hero-line]').forEach((line, index) => animate(line,
      [{ transform: 'translateY(18px)' }, { transform: 'translateY(0px)' }],
      { delay: 80 + index * 65, duration: 800, easing: editorialEase }));
    app.querySelectorAll('[data-hero-rule]').forEach(rule => animate(rule,
      [{ transform: 'scaleX(.35)' }, { transform: 'scaleX(1)' }],
      { delay: 120, duration: 900, easing: editorialEase }));

    const reveal = new IntersectionObserver(entries => {
      for (const entry of entries) {
        if (!entry.isIntersecting) continue;
        reveal.unobserve(entry.target);
        animate(entry.target, [{ opacity: 0, transform: 'translateY(28px)' }, { opacity: 1, transform: 'none' }],
          { duration: 720, delay: entry.target.classList.contains('project-copy') ? 90 : 0, easing: editorialEase }, () => clear(entry.target));
      }
    }, { rootMargin: '0px 0px -48px 0px' });
    app.querySelectorAll('[data-reveal]').forEach(element => {
      const bounds = element.getBoundingClientRect();
      // Slow initialization and restored scroll positions never hide visible copy.
      if (bounds.top < innerHeight && bounds.bottom > 0) return;
      style(element, 'opacity', '0');
      style(element, 'transform', 'translateY(28px)');
      reveal.observe(element);
    });
    disposals.push(() => reveal.disconnect());

    const playArt = scope => {
      if (played.has(scope)) return;
      played.add(scope);
      const artwork = scope.closest('[data-artwork]');
      if (artwork.dataset.artwork === 'hero') {
        animate(scope.querySelector('.convergence-rest'), [
          { opacity: .1, offset: 0 }, { opacity: .1, offset: .85 }, { opacity: 1, offset: 1 },
        ], { duration: 3200 });
        ['blue', 'red', 'yellow', 'green'].forEach((ink, index) => animate(scope.querySelector(`.convergence-${ink}`),
          [{ opacity: 0, transform: `translateX(${[-150, -120, -140, -180][index]}px)` }, { opacity: 1, transform: 'translateX(0px)' }],
          { delay: 120 + index * 260, duration: 2100, easing: inkEase }));
      } else {
        const sequence = sequences[artwork.dataset.artwork];
        scope.querySelectorAll('.project-art-slice').forEach((layer, index) => {
          const [x, y, scale, delay, duration] = sequence[index];
          animate(layer, [{ opacity: .1, transform: `translate(${x}px,${y}px) scale(${scale})` }, { opacity: 1, transform: 'translate(0px,0px) scale(1)' }],
            { delay, duration, easing: inkEase });
        });
      }
    };
    const enteringArt = new IntersectionObserver(entries => {
      for (const entry of entries) if (entry.isIntersecting && entry.intersectionRatio >= .25) {
        enteringArt.unobserve(entry.target);
        playArt(entry.target);
      }
    }, { threshold: .25 });
    const preloadArt = new IntersectionObserver(entries => {
      for (const entry of entries) {
        if (!entry.isIntersecting) continue;
        preloadArt.unobserve(entry.target);
        let images = [...entry.target.querySelectorAll('img[data-art-media]')];
        if (!images.length) {
          const image = new Image();
          image.fetchPriority = 'low';
          image.src = entry.target.querySelector('image').getAttribute('href');
          images = [image];
        }
        Promise.all(images.map(image => { image.loading = 'eager'; image.fetchPriority = 'low'; return image.decode(); }))
          .then(() => { if (!disposed) enteringArt.observe(entry.target); })
          .catch(() => { /* The original static print remains on decode failure. */ });
      }
    }, { rootMargin: `${innerHeight}px 0px` });
    app.querySelectorAll('.hero-art-media, .project-art-window').forEach(scope => preloadArt.observe(scope));
    disposals.push(() => { preloadArt.disconnect(); enteringArt.disconnect(); });

    // One frame loop integrates the original spring parameters, only while
    // pointer values settle or a scroll event changes the printed composition.
    const springs = [];
    const rules = [...app.querySelectorAll('.project-row')];
    let frame;
    let previousTime;
    const schedule = () => { if (frame === undefined && !disposed) frame = requestAnimationFrame(tick); };
    const spring = (surface, stiffness, damping, write) => {
      const state = { x: 0, y: 0, vx: 0, vy: 0, targetX: 0, targetY: 0, stiffness, damping, write, surface };
      springs.push(state);
      return state;
    };
    const tick = time => {
      frame = undefined;
      const elapsed = Math.min(64, previousTime === undefined ? 16 : time - previousTime) / 1000;
      previousTime = time;
      let moving = false;
      for (const state of springs) {
        let remaining = elapsed;
        while (remaining > 0) {
          const dt = Math.min(remaining, 1 / 120);
          state.vx += ((state.targetX - state.x) * state.stiffness - state.vx * state.damping) * dt;
          state.vy += ((state.targetY - state.y) * state.stiffness - state.vy * state.damping) * dt;
          state.x += state.vx * dt; state.y += state.vy * dt;
          remaining -= dt;
        }
        const settled = Math.abs(state.targetX - state.x) + Math.abs(state.targetY - state.y) + Math.abs(state.vx) + Math.abs(state.vy) < .001;
        if (settled) { state.x = state.targetX; state.y = state.targetY; state.vx = 0; state.vy = 0; }
        else moving = true;
        state.write(state);
      }
      for (const row of rules) {
        const bounds = row.getBoundingClientRect();
        const progress = clamp((innerHeight - bounds.top) / (innerHeight + bounds.height));
        style(row.querySelector('.project-rule'), 'transform', `scaleX(${Math.min(1, .12 + progress * 3.52)})`);
      }
      if (moving) schedule(); else previousTime = undefined;
    };
    for (const surface of app.querySelectorAll('[data-pointer], .button, .footer-email')) {
      const hero = surface.dataset.pointer === 'hero';
      const project = surface.dataset.pointer === 'project';
      const state = spring(surface, hero ? 110 : project ? 130 : 240, project ? 24 : 22, current => {
        if (hero) {
          const bounds = surface.getBoundingClientRect();
          const scroll = clamp(-bounds.top / bounds.height);
          style(surface.querySelector('.portrait-ink-blue'), 'transform', `translate(${current.x * 22 + scroll * 10}px,${current.y * 14 - scroll * 22}px)`);
          style(surface.querySelector('.portrait-ink-red'), 'transform', `translate(${current.x * -14 - scroll * 8}px,${current.y * -10 + scroll * 16}px)`);
        } else if (project) {
          style(surface.querySelector('.project-art-pointer'), 'transform', `translate(${current.x * 10}px,${current.y * 7}px)`);
        } else style(surface, 'transform', `translate(${current.x}px,${current.y}px)`);
      });
      const reset = () => { state.targetX = 0; state.targetY = 0; schedule(); };
      listen(surface, 'pointermove', event => {
        if (!fine.matches || event.pointerType === 'touch') return;
        const bounds = surface.getBoundingClientRect();
        const x = event.clientX - bounds.left;
        const y = event.clientY - bounds.top;
        state.targetX = hero || project ? Math.max(-1, Math.min(1, x / bounds.width * 2 - 1)) : (x / bounds.width - .5) * 8;
        state.targetY = hero || project ? Math.max(-1, Math.min(1, y / bounds.height * 2 - 1)) : (y / bounds.height - .5) * 6;
        schedule();
      });
      listen(surface, 'pointerleave', reset); listen(surface, 'pointercancel', reset); listen(surface, 'blur', reset);
      if (!hero && !project) {
        listen(surface, 'pointerdown', () => animate(surface, [{ scale: 1 }, { scale: .97 }], { duration: 90 }));
      }
    }
    listen(fine, 'change', () => { for (const state of springs) { state.x = state.y = state.vx = state.vy = state.targetX = state.targetY = 0; } schedule(); });
    listen(window, 'scroll', schedule, { passive: true });
    listen(window, 'resize', schedule, { passive: true });
    schedule();
    teardown = () => {
      disposed = true;
      if (frame !== undefined) cancelAnimationFrame(frame);
      animations.forEach(animation => animation.cancel());
      disposals.forEach(dispose => dispose());
      styled.forEach(clear);
    };
  };
  const preferenceChanged = () => { teardown(); teardown = () => {}; start(); };
  reduced.addEventListener('change', preferenceChanged);
  start();
  return () => { teardown(); reduced.removeEventListener('change', preferenceChanged); };
}
