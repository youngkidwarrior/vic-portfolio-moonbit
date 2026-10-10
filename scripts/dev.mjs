import fs from 'node:fs';
import path from 'node:path';
import { createServer } from 'vite';
import { root } from './toolchain.mjs';
import { compile } from './compile.mjs';
import { documentHtml } from './document.mjs';

let { render, renderer } = await compile();
const port = Number(process.env.PORT || 5173);
const server = await createServer({
  root: path.join(root, 'web'),
  publicDir: path.join(root, 'public'),
  server: { host: '127.0.0.1', port, strictPort: true },
  plugins: [{ name: 'moonbit-prerendered-routes', configureServer(vite) {
    vite.middlewares.use(async (request, response, next) => {
      const pathname = new URL(request.url, 'http://localhost').pathname.replace(/\/$/, '') || '/';
      if (request.method !== 'GET' || pathname.includes('.') || pathname.startsWith('/@') || pathname.startsWith('/node_modules/')) return next();
      try {
        const html = await vite.transformIndexHtml(pathname, documentHtml(render(pathname)));
        response.statusCode = renderer.route_status(pathname);
        response.setHeader('Content-Type', 'text/html; charset=utf-8');
        response.end(html);
      } catch (error) { next(error); }
    });
  } }],
});
await server.listen();
server.printUrls();
const watchDirectories = [root, path.join(root, 'cmd/browser'), path.join(root, 'content')];
let rebuildTimer;
let rebuilding = false;
for (const directory of watchDirectories.filter(fs.existsSync)) {
  fs.watch(directory, (_event, file) => {
    if (!file || !/\.(mbt|json)$|^moon\.(mod|pkg)$/.test(file)) return;
    clearTimeout(rebuildTimer);
    rebuildTimer = setTimeout(async () => {
      if (rebuilding) return;
      rebuilding = true;
      try { ({ render, renderer } = await compile()); server.ws.send({ type: 'full-reload' }); }
      catch (error) { console.error(error); }
      finally { rebuilding = false; }
    }, 180);
  });
}
