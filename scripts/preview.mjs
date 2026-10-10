import fs from 'node:fs';
import path from 'node:path';
import http from 'node:http';
import { root } from './toolchain.mjs';

const output = path.join(root, 'dist');
const types = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript; charset=utf-8', '.css': 'text/css; charset=utf-8', '.json': 'application/json', '.wasm': 'application/wasm', '.svg': 'image/svg+xml', '.webp': 'image/webp', '.jpg': 'image/jpeg', '.png': 'image/png', '.woff2': 'font/woff2', '.pdf': 'application/pdf' };
if (!fs.existsSync(path.join(output, 'index.html'))) throw new Error('Build the portfolio before starting the preview.');
const server = http.createServer((request, response) => {
  let pathname;
  try { pathname = decodeURIComponent(new URL(request.url, 'http://localhost').pathname); }
  catch { response.writeHead(400); return response.end('Invalid URL'); }
  let file = path.resolve(output, `.${pathname}`);
  if (file !== output && !file.startsWith(`${output}${path.sep}`)) { response.writeHead(403); return response.end('Forbidden'); }
  if (fs.existsSync(file) && fs.statSync(file).isDirectory()) file = path.join(file, 'index.html');
  let status = 200;
  if (!fs.existsSync(file) || !fs.statSync(file).isFile()) {
    status = 404;
    if (path.extname(pathname)) { response.writeHead(status); return response.end('Not found'); }
    file = path.join(output, '404.html');
  }
  const type = types[path.extname(file)] || 'application/octet-stream';
  response.writeHead(status, {
    'Content-Type': type, 'Cache-Control': 'no-cache',
    'Content-Length': fs.statSync(file).size,
  });
  if (request.method === 'HEAD') return response.end();
  fs.createReadStream(file).pipe(response);
});
server.listen(Number(process.env.PORT || 5174), '127.0.0.1', () => console.log(`Portfolio preview: http://127.0.0.1:${server.address().port}`));
