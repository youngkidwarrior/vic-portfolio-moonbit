import fs from 'node:fs';
import path from 'node:path';
import { build } from 'vite';
import { root } from './toolchain.mjs';
import { compile, routes } from './compile.mjs';
import { documentHtml } from './document.mjs';

const { render } = await compile();
await build({ root: path.join(root, 'web'), publicDir: path.join(root, 'public'), build: { outDir: path.join(root, 'dist'), emptyOutDir: true } });
const output = fs.readFileSync(path.join(root, 'dist/index.html'), 'utf8');
const scripts = [...output.matchAll(/<script\b[^>]*type="module"[^>]*>.*?<\/script>/gs)].map(match => match[0]).join('\n');
const styles = [...output.matchAll(/<link\b[^>]*rel="stylesheet"[^>]*>/g)].map(match => match[0]).join('\n');
if (!scripts) throw new Error('Vite produced no browser entry script.');
if (!styles) throw new Error('Vite produced no release stylesheet.');
for (const route of routes) {
  const dir = path.join(root, 'dist', route.slice(1));
  fs.mkdirSync(dir, { recursive: true });
  fs.writeFileSync(path.join(dir, 'index.html'), documentHtml({ ...render(route), scripts, styles }));
}
fs.writeFileSync(path.join(root, 'dist/404.html'), documentHtml({ ...render('/not-found'), scripts, styles }));
console.log(`Prerendered ${routes.length} routes with the MoonBit renderer.`);
