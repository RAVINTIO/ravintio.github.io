# System Context

Last updated: 0000009-bug-fixes

---

## What This Repo Is

The `ravintio.github.io` repo holds the public RAVINTIO documentation site. GitHub Pages serves it at the org root, `https://ravintio.github.io`. RAVINTIO Zero manages the repo, so every change runs through its pipeline.

---

## People and Systems

| Actor | Relationship |
|-------|--------------|
| Readers | Read the site in a browser. The site keeps no reader data. |
| Maintainers | Run feature work through RAVINTIO Zero, then push and merge. |
| GitHub Actions | Builds the site and runs the tests on merge to `main`. |
| GitHub Pages | Hosts the built site. |
| `RAVINTIO/ravintio-zero` | The source of the installed pack and the target of the site's GitHub links. |

---

## The Two Components

- **`site-content`** (`src/site-content/`) owns the Markdown pages. Every text edit starts here.
- **`web-app`** (`src/web-app/`) builds the pages into HTML, owns the nav manifest, and runs the tests.

---

## The Build Pipeline

1. `node scripts/build-docs.js` reads the manifest and every page, then writes HTML to `src/web-app/docs/`.
2. Vite bundles the homepage and every page into `dist/`.

`npm run dev` and `npm run build` run both stages. `npm test` runs the tests against `dist/`.

---

## Deployment

`.github/workflows/deploy.yml` runs on merge to `main`. It builds the site and publishes `dist/` to GitHub Pages.

---

## How This Repo Uses RAVINTIO Zero

The pack sits in `ravintio-zero/`. Each change runs through five phases, from P0 Discovery to P4 Ship. Active run state lives in `plan/current/`. Finished runs move to `plan/_archive/`, and change records go to `plan/changelog/`.
