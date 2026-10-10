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

## Dependencies and tradeoffs

`justjavac/template@0.1.1` supplies escaped HTML rendering primitives without a browser framework or target restriction. Rabbita 0.13.1 was inspected but its actual manifests support JavaScript and native, which does not meet the Wasm browser target. The template package is pinned in `moon.mod`; JavaScript dev/test dependencies are pinned in `package.json` and `bun.lock`.

`content/site.json` and `content/resume.json` preserve the original portfolio data. The initial port uses native web animations and view transitions; their timing, pointer easing, and transition composition differ from React Motion and React Router. Exact animation parity and physical-device pacing have not been established. The portfolio has not been deployed.

SeekMoon authors the MoonBit source through the authenticated local CLI launcher; Codex owns the browser host and build integration and independently verifies the resulting artifact. No formal proofs are promised for this UI port.
