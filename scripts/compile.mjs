import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { root, runMoon } from './toolchain.mjs';
import { documentHtml } from './document.mjs';

export const routes = ['/', '/work/send', '/work/shenanigan', '/work/brightid', '/work/open-source', '/resume'];

export async function compile({ release = false } = {}) {
  if (!fs.existsSync(path.join(root, 'cmd/browser/moon.pkg'))) {
    throw new Error('Missing cmd/browser/moon.pkg. Run the build from a complete project checkout.');
  }
  const mode = release ? ['--release'] : [];
  runMoon(['build', ...mode, '--target', 'wasm-gc', '--deny-warn', 'cmd/browser'], `build-wasm-gc-${release ? 'release' : 'debug'}`);
  runMoon(['build', ...mode, '--target', 'js', '--deny-warn', 'cmd/browser'], `build-js-${release ? 'release' : 'debug'}`);
  fs.mkdirSync(path.join(root, 'public/runtime'), { recursive: true });
  fs.mkdirSync(path.join(root, 'public/content'), { recursive: true });
  for (const [target, extension] of [['wasm-gc', 'wasm'], ['js', 'js']]) {
    fs.copyFileSync(path.join(root, `_build/${target}/${release ? 'release' : 'debug'}/build/cmd/browser/browser.${extension}`), path.join(root, `public/runtime/portfolio.${extension}`));
  }
  for (const filename of ['site.json', 'resume.json']) fs.copyFileSync(path.join(root, 'content', filename), path.join(root, 'public/content', filename));
  const renderer = await import(`${pathToFileURL(path.join(root, 'public/runtime/portfolio.js')).href}?build=${Date.now()}`);
  const site = fs.readFileSync(path.join(root, 'content/site.json'), 'utf8');
  const resume = fs.readFileSync(path.join(root, 'content/resume.json'), 'utf8');
  const content = renderer.create_renderer(site, resume);
  const render = route => ({ body: renderer.render_with(content, route, new Date().getFullYear()), metadata: JSON.parse(renderer.metadata_with(content, route)) });
  fs.writeFileSync(path.join(root, 'web/index.html'), documentHtml({ ...render('/'), ...(release ? { styles: '<link rel="stylesheet" href="/styles.css">' } : {}) }));
  return { render, renderer };
}
