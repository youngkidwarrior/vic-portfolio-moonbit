# Victor Ginelli portfolio in MoonBit

This first port preserves the six routes, public content, authentic images, fonts, and downloadable résumé from the React portfolio in `/Users/vict0xr/Documents/Shenanigan/vic-web` at revision `026901088cf08d5606da24596a49bff048675dcc`.

MoonBit owns route interpretation, page rendering, metadata, and theme/menu decisions. The browser host integrates DOM events, history, focus, storage, pointer response, and browser-native animations. It runs the Wasm GC build in recent browsers; the same MoonBit source compiles to JavaScript for prerendering and compatibility. Static HTML remains readable before the runtime loads and with JavaScript disabled.

## Development

Requirements are Node 20+, Bun, and MoonBit. In this workspace the scripts select `../.tools/moon`; elsewhere, set `MOON_HOME` to an installed toolchain. Both compiler and companion executables use that toolchain's bin directory.

```sh
bun install
bun run dev
```

The dev server listens at `http://127.0.0.1:5173`, rebuilds MoonBit/content changes, and uses Vite for browser-host changes. Set `PORT` to use another port. The build emits six static routes and a 404 page into `dist/`.

```sh
bun run check
bun run build
bunx playwright install chromium
bun run test:e2e
```

The checks cover both Wasm GC and JavaScript targets. Browser checks cover desktop/mobile routes, both themes, content/images, accessibility, navigation/history, PDF delivery, reduced motion, and no-JavaScript rendering. Browser reports live in `evidence/browser-results.json`; compiler logs live in `evidence/checks/`. SeekMoon requests and terminal reports live in `evidence/seekmoon/`.

Release builds use MoonBit compiler optimization, one minified stylesheet, and precomputed Brotli/gzip assets. The local preview (`node scripts/preview.mjs`) negotiates compression; deployment hosting must also serve the sidecars or provide equivalent compression.

Computer-use comparison after the layout repairs matched production's rounded main heights on the homepage, Send case study, and résumé at 1440, 768, 390, and 320 pixels. The mobile menu also matched. Results, source hashes, and exported Chrome Lighthouse reports are in `evidence/parity-fix/`. The final browser suite passed 27 checks with one redundant mobile-project skip.

Two cold mobile Lighthouse runs measured production at 1.54–1.65s first paint and 2.30–2.32s largest paint; the final release measured 1.21s and 3.05s. Both had zero blocking time and layout shift. The dev build's single run measured 3.01s and 6.31s. These compare a remote production host with a local preview under the same simulated slow 4G/CPU settings, and do not establish a language performance advantage. The remaining largest-paint gap needs further profiling.

## Dependencies and tradeoffs

`justjavac/template@0.1.1` supplies escaped HTML rendering primitives without a browser framework or target restriction. Rabbita 0.13.1 was inspected but its actual manifests support JavaScript and native, which does not meet the Wasm browser target. The template package is pinned in `moon.mod`; JavaScript dev/test dependencies are pinned in `package.json` and `bun.lock`.

`content/site.json` and `content/resume.json` preserve the original portfolio data. Native web animations now follow the original entrance and artwork sequence parameters, pointer spring settings, and selected-project image/frame transitions. Exact spring integration and physical-device pacing have not been established. Eight original icon paths still require SeekMoon authoring; automatic approval review blocked the external-provider request pending explicit data-sharing approval. The portfolio has not been deployed.

SeekMoon authors the MoonBit source through the authenticated local CLI launcher; Codex owns the browser host and build integration and independently verifies the resulting artifact. No formal proofs are promised for this UI port.
