// Isolated, bounded comparison. No generated files in the working site are changed.
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import http from 'node:http';
import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { brotliCompressSync, gzipSync, constants } from 'node:zlib';
import assert from 'node:assert/strict';
import { chromium } from '@playwright/test';
import { root, env, moon, moonHome } from './toolchain.mjs';

const trials = Number(process.env.BENCH_TRIALS || 10);
if (!Number.isInteger(trials) || trials < 2 || trials > 30) throw new Error('BENCH_TRIALS must be 2–30.');
const port = Number(process.env.BENCH_PORT || 5178);
const scratch = fs.mkdtempSync(path.join(os.tmpdir(), 'portfolio-benchmark-'));
const output = path.resolve(root, process.env.BENCH_OUTPUT_DIR || 'evidence/benchmark');
const brotli = bytes => brotliCompressSync(bytes, { params: { [constants.BROTLI_PARAM_QUALITY]: 9 } });
fs.mkdirSync(output, { recursive: true });
const sha = bytes => createHash('sha256').update(bytes).digest('hex');
const command = (program, args, cwd = root) => {
  const result = spawnSync(program, args, { cwd, env, encoding: 'utf8', timeout: 180000 });
  if (result.error || result.status !== 0) throw new Error(`${program} ${args.join(' ')}: ${result.error || result.stderr}`);
  return result.stdout.trim();
};
const sourceFiles = command('git', ['ls-files', '--cached', '--others', '--exclude-standard', '-z']).split('\0').filter(Boolean).filter(file => fs.existsSync(path.join(root, file)));
const sourceHash = sha(sourceFiles.sort().map(file => `${file}\0${sha(fs.readFileSync(path.join(root, file)))}`).join('\n'));
let server;
let browser;
try {
  fs.cpSync(root, scratch, { recursive: true, filter: source => !['.git', '_build', 'node_modules', '.mooncakes', 'dist', 'evidence', 'test-results'].includes(path.basename(source)) });
  for (const name of ['node_modules', '.mooncakes']) fs.symlinkSync(path.join(root, name), path.join(scratch, name), 'dir');
  // Instrument only this temporary build. Both backends use the SAME host bytes.
  const hostPath = path.join(scratch, 'web/host.js');
  let host = fs.readFileSync(hostPath, 'utf8');
  const replace = (before, after) => {
    assert.equal(host.split(before).length, 2, `Benchmark instrumentation anchor: ${before}`);
    host = host.replace(before, after);
  };
  replace('async function loadRenderer() {', `async function loadRenderer() {
  if (document.documentElement.dataset.benchmarkBackend === 'js') {
    const url = '/runtime/portfolio.js';
    return { api: await import(/* @vite-ignore */ url), target: 'js' };
  }`);
  replace('async function initialize() {', "async function initialize() {\n  performance.mark('portfolio-start');");
  replace('  content = renderer.create_renderer(site, resume);', `  performance.mark('portfolio-content-start');
  content = renderer.create_renderer(site, resume);
  performance.mark('portfolio-content-end');
  window.__benchmark = { renderer, content, site, resume };`);
  replace('  root.dataset.runtime = runtime.target;', "  root.dataset.runtime = runtime.target;\n  performance.mark('portfolio-ready');");
  fs.writeFileSync(hostPath, host);
  const buildLog = command(process.execPath, ['scripts/build.mjs'], scratch);
  fs.writeFileSync(path.join(output, 'build.log'), buildLog);
  const dist = path.join(scratch, 'dist');
  let backend = 'wasm-gc';
  const types = { '.html': 'text/html', '.js': 'text/javascript', '.css': 'text/css', '.json': 'application/json', '.wasm': 'application/wasm', '.woff2': 'font/woff2', '.svg': 'image/svg+xml', '.webp': 'image/webp', '.jpg': 'image/jpeg', '.png': 'image/png' };
  const compressedAssets = new Map();
  for (const entry of fs.readdirSync(dist, { recursive: true })) {
    const file = path.join(dist, entry);
    if (fs.statSync(file).isFile() && !/\.(br|gz)$/.test(file)) compressedAssets.set(file, brotli(fs.readFileSync(file)));
  }
  const htmlCache = new Map();
  for (const [file] of compressedAssets) {
    if (!file.endsWith('.html')) continue;
    for (const target of ['js', 'wasm-gc']) {
      const original = fs.readFileSync(file, 'utf8');
      assert.equal(original.split('<html lang="en">').length, 2);
      assert.equal(original.split('<link rel="preload" href="/runtime/portfolio.wasm" as="fetch" type="application/wasm" crossorigin>').length, 2);
      let html = original.replace('<html lang="en">', `<html lang="en" data-benchmark-backend="${target}">`);
      if (target === 'js') html = html.replace('<link rel="preload" href="/runtime/portfolio.wasm" as="fetch" type="application/wasm" crossorigin>', '<link rel="modulepreload" href="/runtime/portfolio.js" crossorigin>');
      htmlCache.set(`${target}:${file}`, brotli(Buffer.from(html)));
    }
  }
  server = http.createServer((req, res) => {
    const pathname = new URL(req.url, 'http://localhost').pathname;
    let file = path.resolve(dist, `.${pathname}`);
    if (!file.startsWith(`${dist}/`)) file = path.join(dist, 'index.html');
    if (fs.existsSync(file) && fs.statSync(file).isDirectory()) file = path.join(file, 'index.html');
    if (!fs.existsSync(file)) { res.writeHead(404); return res.end(); }
    const compressed = htmlCache.get(`${backend}:${file}`) || compressedAssets.get(file);
    res.writeHead(200, { 'Content-Type': types[path.extname(file)] || 'application/octet-stream', 'Content-Encoding': 'br', 'Content-Length': compressed.length, 'Cache-Control': 'no-store', Vary: 'Accept-Encoding' });
    res.end(compressed);
  });
  await new Promise((resolve, reject) => { server.once('error', reject); server.listen(port, '127.0.0.1', resolve); });
  const samples = [];
  let browserVersion;
  let parity;
  for (let trial = 0; trial < trials; trial++) {
    for (const target of trial % 2 ? ['js', 'wasm-gc'] : ['wasm-gc', 'js']) {
      backend = target;
      browser = await chromium.launch({ headless: true });
      browserVersion = browser.version();
      const context = await browser.newContext({ viewport: { width: 1440, height: 1000 }, colorScheme: 'light', reducedMotion: 'reduce' });
      try {
        const page = await context.newPage();
        const errors = [];
        page.on('pageerror', error => errors.push(error.message));
        await page.addInitScript(() => {
          window.__paints = [];
          new PerformanceObserver(list => window.__paints.push(...list.getEntries().map(({ name, startTime }) => ({ name, startTime })))).observe({ type: 'paint', buffered: true });
        });
        await page.goto(`http://127.0.0.1:${port}/`, { waitUntil: 'load' });
        await page.waitForFunction(() => document.documentElement.dataset.runtime);
        assert.equal(await page.getAttribute('html', 'data-runtime'), target);
        await page.waitForFunction(() => window.__paints.some(entry => entry.name === 'first-contentful-paint'), null, { timeout: 10000 });
        const sample = await page.evaluate(() => {
          const { renderer: api, content, site, resume } = window.__benchmark;
          const routes = ['/', '/work/send', '/work/shenanigan', '/work/brightid', '/work/open-source', '/resume', '/unknown'];
          const mark = name => performance.getEntriesByName(name)[0].startTime;
          const outputs = routes.map(route => [api.render_with(content, route, 2026), api.metadata_with(content, route)]);
          for (let i = 0; i < routes.length; i++) {
            if (outputs[i][0] !== api.render_page(routes[i], site, resume, 2026) || outputs[i][1] !== api.page_metadata(routes[i], site, resume)) throw new Error('Legacy API equivalence failed');
          }
          // Exercise explicit contexts across changed input, failure and recovery on both backends.
          const changed = api.create_renderer(site.replaceAll('Victor Ginelli', 'Another Author'), resume.replaceAll('Victor Ginelli', 'Resume Author'));
          if (!api.render_with(changed, '/resume', 2027).includes('Resume Author') || !api.render_with(changed, '/', 2027).includes('© 2027 Another Author')) throw new Error('Context/year isolation failed');
          for (const args of [['{', resume], [site, '{'], ['{}', resume], [site, '{}']]) {
            let failed = false;
            try { api.create_renderer(...args); } catch { failed = true; }
            if (!failed) throw new Error('Invalid context accepted');
          }
          if (api.render_with(content, '/', 2026) !== outputs[0][0]) throw new Error('Context poisoned');
          const recovered = api.create_renderer(site, resume);
          if (api.metadata_with(recovered, '/') !== outputs[0][1]) throw new Error('Recovery failed');
          const time = action => { const start = performance.now(); for (let i = 0; i < 100; i++) action(i); return (performance.now() - start) / 100; };
          // Fixed warm-up count and identical routes/work for each backend.
          for (let i = 0; i < 100; i++) { api.render_with(content, routes[i % routes.length], 2026); api.metadata_with(content, routes[i % routes.length]); }
          return {
            readyMs: mark('portfolio-ready'), initializeMs: mark('portfolio-ready') - mark('portfolio-start'), validationMs: mark('portfolio-content-end') - mark('portfolio-content-start'),
            fcpMs: window.__paints.find(entry => entry.name === 'first-contentful-paint')?.startTime ?? null,
            renderAndMetadataMs: time(i => { api.render_with(content, routes[i % routes.length], 2026); api.metadata_with(content, routes[i % routes.length]); }),
            statelessRenderAndMetadataMs: time(i => { api.render_page(routes[i % routes.length], site, resume, 2026); api.page_metadata(routes[i % routes.length], site, resume); }),
            repeatedValidationMs: time(() => api.create_renderer(site, resume)), outputs,
            resources: performance.getEntriesByType('resource').map(({ name, encodedBodySize, decodedBodySize, transferSize }) => ({ path: new URL(name).pathname, encodedBodySize, decodedBodySize, transferSize })),
          };
        });
        assert(sample.resources.some(resource => resource.path === `/runtime/portfolio.${target === 'js' ? 'js' : 'wasm'}`), 'Selected runtime was not requested');
        assert(!sample.resources.some(resource => resource.path === `/runtime/portfolio.${target === 'js' ? 'wasm' : 'js'}`), 'Unselected runtime was requested');
        const hash = sha(JSON.stringify(sample.outputs));
        parity ??= hash;
        assert.equal(hash, parity, 'Backend output equivalence');
        delete sample.outputs;
        // A real delegated click path, measured in-page to exclude the driver round trip.
        sample.navigationTrialsMs = await page.evaluate(async () => {
          const measurements = [];
          for (let i = 0; i < 12; i++) {
            const destination = i % 2 ? '/' : '/resume';
            const start = performance.now();
            const finished = new Promise(resolve => {
              const observer = new MutationObserver(() => {
                if (location.pathname === destination && document.querySelector(destination === '/' ? '.hero' : '.resume-page')) { observer.disconnect(); requestAnimationFrame(() => requestAnimationFrame(() => resolve(performance.now() - start))); }
              });
              observer.observe(document.getElementById('app'), { childList: true });
            });
            document.querySelector(`a[href="${destination}"]`).click();
            measurements.push(await Promise.race([finished, new Promise((_, reject) => setTimeout(() => reject(new Error('Navigation timed out')), 10000))]));
          }
          return measurements;
        });
        sample.navigationMs = sample.navigationTrialsMs.reduce((sum, value) => sum + value, 0) / sample.navigationTrialsMs.length;
        assert.deepEqual(errors, []);
        samples.push({ trial, backend: target, ...sample });
        console.log(`Trial ${trial + 1}/${trials} ${target}: ready ${sample.readyMs.toFixed(1)} ms, render+metadata ${sample.renderAndMetadataMs.toFixed(3)} ms`);
      } finally { await context.close(); await browser.close(); browser = undefined; }
    }
  }
  const artifacts = fs.readdirSync(path.join(dist, 'assets')).filter(file => file.endsWith('.js')).map(file => `assets/${file}`).concat(['runtime/portfolio.js', 'runtime/portfolio.wasm', 'content/site.json', 'content/resume.json']);
  const payloads = artifacts.map(file => { const bytes = fs.readFileSync(path.join(dist, file)); return { file, sha256: sha(bytes), raw: bytes.length, gzip: gzipSync(bytes, { level: 9 }).length, brotli: brotli(bytes).length }; });
  const metrics = ['readyMs', 'initializeMs', 'validationMs', 'fcpMs', 'renderAndMetadataMs', 'statelessRenderAndMetadataMs', 'repeatedValidationMs', 'navigationMs'];
  const summaries = Object.fromEntries(['wasm-gc', 'js'].map(target => [target, Object.fromEntries(metrics.map(metric => {
    const values = samples.filter(sample => sample.backend === target).map(sample => sample[metric]).filter(value => value !== null).sort((a,b) => a-b);
    return [metric, { median: (values[Math.floor((values.length - 1) / 2)] + values[Math.floor(values.length / 2)]) / 2, min: values[0], max: values.at(-1), n: values.length }];
  }))]));
  const report = { timestamp: new Date().toISOString(), head: command('git', ['rev-parse', 'HEAD']), sourceSha256: sourceHash, benchmarkSha256: sha(fs.readFileSync(path.join(root, 'scripts/benchmark.mjs'))), moon: command(moon, ['version', '--all']), moonPath: moon, moonHome, node: process.version, browser: browserVersion, platform: `${os.platform()} ${os.release()} ${os.arch()}`, cpu: os.cpus()[0].model, settings: { trialsPerBackend: trials, origin: `http://127.0.0.1:${port}`, viewport: '1440x1000', reducedMotion: 'reduce', throttling: 'none', cache: 'fresh Chromium process and context per load; HTTP no-store; OS filesystem caches uncontrolled', order: 'alternating paired trials', compression: 'precomputed brotli quality 9 for every resource; gzip payload sizes level 9', steadyIterations: 100, warmupIterations: 100, host: 'same instrumented host bytes; only backend attribute and matching preload differ in HTML' }, equivalenceSha256: parity, payloads, summaries, samples };
  fs.writeFileSync(path.join(output, 'results.json'), JSON.stringify(report, null, 2));
  console.log(JSON.stringify(summaries, null, 2));
  console.log(`Evidence: ${output}/results.json`);
} finally {
  await browser?.close();
  if (server) await new Promise(resolve => server.close(resolve));
  fs.rmSync(scratch, { recursive: true, force: true });
}
