# Dependencies - web-app

## Upstream

| Dependency | Type | Description |
|-----------|------|-------------|
| `site-content` | filesystem, build time | Markdown pages in `src/site-content/pages/` |
| `ravintio-zero/` | filesystem, test time | The reference-match test reads the pack folders |
| `docs.manifest.json` | internal config | Sections, page order, and titles, owned by `web-app` |
| Chromium | browser, test time | Installed by `npx playwright install chromium` |

## Downstream

None. GitHub Pages serves `dist/` through `.github/workflows/deploy.yml`.

## npm packages

| Package | Version | Purpose |
|---------|---------|---------|
| `marked` | ^17.0.4 | Converts Markdown to HTML in `build-docs.js` |
| `mermaid` | ^12.2.0 | Draws diagrams in the browser, loaded on demand |
| `vite` | ^7.3.1 | Bundler and dev server |
| `typescript` | ~5.9.3 | Type checking |
| `@playwright/test` | 1.64.1, exact | Runs the regression suite in Chromium. Patch updates within `1.64.x` are allowed. |

The content suite uses only Node built-ins (`node:test`, `node:assert`, `node:fs`). The regression suite uses `@playwright/test` and a Chromium download. See ADR-001 of feature 0000016.
