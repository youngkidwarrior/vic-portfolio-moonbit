# Portfolio first port implementation plan

**Goal:** A Git-initialized MoonBit portfolio, running on localhost for review.
**Scope:** Preserve the six original routes, public content, assets, typography, responsive layout, theme controls, keyboard access, and reduced-motion support.
**Non-goals:** Deployment and exact equivalence to Motion's springs and React Router's native view-transition implementation.
**Risks:** Wasm GC and JavaScript string builtins require a recent browser; browser hosting still needs JavaScript. Exact Motion spring and React Router transition equivalence needs a later visual review.

## Files and order

1. Provision `moon.mod`, `content/site.json`, `content/resume.json`, `public/`, `package.json`, and `scripts/`. Original source: `/Users/vict0xr/Documents/Shenanigan/vic-web`, revision `026901088cf08d5606da24596a49bff048675dcc`. Risk: low. Preserve original source.
2. Author the root rendering/data/route packages and `cmd/browser/` through SeekMoon. MoonBit owns route interpretation, content rendering, and UI state decisions. Risk: low. Use `justjavac/template@0.1.1` for escaping and rendering primitives; its installed manifests have no target restriction. Rabbita 0.13.1 was examined and rejected because its manifests support only JavaScript and native.
3. Implement `web/host.js`, `scripts/build.mjs`, and `scripts/dev.mjs`. Compile a Wasm GC renderer and the same renderer to JavaScript for static generation and browser compatibility. Keep content readable before runtime loading. Use browser-native events and animation for integration. Risk: low.
4. Run `bun run check`, `bun run build`, and `bun run test:e2e`. Verify all routes, unknown routes, local assets, theme persistence, navigation/back, mobile overflow, no-JavaScript content, and reduced motion. Risk: low. Retain reports in `evidence/`.
5. Start the local dev process, verify its HTTP response and rendered UI, and open the page in Codex. Review visual pacing separately from mechanical tests. Risk: low.

## Authorship and evidence

The installed SeekMoon app is version 0.2.15. Its bundled engine is `/Applications/SeekMoon.app/Contents/Resources/seekmoon/bin/openseek` (SHA-256 `9a8fa874c4e8e7e9cf223276233ed52dfb49146813b926d6ecc2f2dcfb5e06e0`). The initial probe failed with missing authentication; the user stopped the port for CLI setup, then authorized resumption. The authenticated launcher at `../scripts/seekmoon-cli.mjs` now passes the app's saved DeepSeek key to the same engine through its child environment. A live authentication response, actual `mbtx` reads, and a selected-toolchain `moon version --all` invocation passed. The helper requires allowlisted bare `moon` with the selected bin on PATH, rather than an absolute executable path. First author request: `evidence/seekmoon/author-1/request.json`, 100 steps and 720 seconds. Codex owns JavaScript/CSS/build/browser tests; SeekMoon owns MoonBit source and manifests.

The selected local compiler is `../.tools/moon/bin/moon`: moon 0.1.20260920, moonc v0.10.14+7d59c7ec9. Commands must supply its `MOON_HOME` and bin directory on child PATH. No proofs are promised for this UI port.

## Completed verification

The first author request completed with process exit 0. Independent compilation and both sets of 10 MoonBit tests passed. The first build exposed a browser export ABI mismatch: raising wrappers returned result objects rather than strings. A separate 30-step, 300-second request (`evidence/seekmoon/repair-2/request.json`) completed with exit 0 and repaired only the browser wrapper boundary and PDF filename. The root library retains typed configuration errors; browser exports abort explicitly for invalid content.

The production and dev import paths required a dynamic URL variable for the copied JavaScript fallback. The initial browser run passed 25/26 checks and exposed an eight-pixel native view-transition scroll shift. Disabling view transitions restored the exact position; disabling reveal transforms did not. The host now restores the requested position after the native transition finishes. The final suite passed 26/26 checks with no retries, including real Wasm GC execution, JavaScript rendering parity and fallback, both themes, keyboard navigation, image loading, accessibility, PDF/metadata/404 delivery, reduced motion, and no-JavaScript pages.

The verified dev process is running at `http://127.0.0.1:5173` and the browser tab was left open. Its DOM reports `data-runtime="wasm-gc"`. Source identity and independent evidence are recorded in `evidence/source-manifest.json` and `evidence/verification.md`. The original source remains clean at the recorded revision. Exact React Motion timing, Safari/Firefox behavior, and physical-device pacing remain outside the verified first-port scope.
