# Victor Ginelli portfolio

A six-route portfolio built with MoonBit, CSS, and a small JavaScript browser host. Pages are prerendered to HTML and remain readable without JavaScript.

MoonBit handles routes, HTML, metadata, and theme/menu state decisions. The browser host handles DOM events, history, focus, storage, and animations. Browsers use Wasm GC with a JavaScript fallback. `justjavac/template@0.1.1` provides HTML escaping. Both backends share an explicit `Renderer` context that validates content once; stateless rendering APIs remain available.

## Development

Install Node.js 20+, Bun, and MoonBit. Set `MOON_HOME` to the toolchain installation directory (normally `$HOME/.moon`):

```sh
export MOON_HOME="$HOME/.moon"
export PATH="$MOON_HOME/bin:$PATH"
bun install
moon update
bun run dev
```

Open `http://127.0.0.1:5173`. Set `PORT` to choose another port. Edit portfolio data in `content/`, MoonBit rendering in the root package, browser integration in `web/`, and assets/styles in `public/`.

## Build and test

```sh
bun run check
bunx playwright install chromium
bun run test:e2e
bun run build
node scripts/preview.mjs
```

`check` validates both MoonBit targets, tests, generated interfaces, and formatting. Browser tests build a release and cover desktop/mobile routes, themes, accessibility, navigation/history, fallback, reduced motion, and no-JavaScript rendering. Test reports stay local in `evidence/`.

The release in `dist/` contains six static routes and a 404 page. Preview listens on port 5174 (`PORT` overrides it). Release assets include Brotli/gzip sidecars; configure the deployment host to serve these or provide equivalent compression.

## Backend comparison

Run `bun run benchmark` after installing Chromium. The isolated harness compares release JS and Wasm builds on one local origin with fresh browser processes, matching assets/compression, and output-equivalence checks. It leaves generated development files alone. See the [benchmark method and sample results](docs/benchmarks/2026-10-10-backends.md) for settings and limitations.

## License

[Apache-2.0](LICENSE).
