# Contributor guidance

- Keep route/content rendering in MoonBit and browser effects in `web/`.
- Preserve static HTML, JavaScript fallback, keyboard access, themes, and reduced-motion behavior.
- Follow MoonBit's `///|` block convention. Add behavioral tests beside the package in `_wbtest.mbt` files.
- Set `MOON_HOME` as described in the README. Run `moon info` and `moon fmt` with that toolchain after MoonBit changes; review generated `.mbti` diffs for intended API changes.
- Run `bun run check` for MoonBit changes and `bun run test:e2e` for browser/build changes. Keep generated output and local test reports out of commits.
