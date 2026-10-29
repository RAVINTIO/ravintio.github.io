# RAVINTIO docs

This repo holds the RAVINTIO documentation site. GitHub Pages serves it at `https://ravintio.github.io`. The repo is `RAVINTIO/ravintio.github.io`, which GitHub serves at the org root.

The site explains what RAVINTIO is and describes its six tools. It also teaches you to adopt RAVINTIO Zero. This repo uses RAVINTIO Zero to manage its own changes.

## Repository structure

| Folder | Holds |
|--------|-------|
| `src/site-content/` | The Markdown pages, in `pages/`, and the component docs |
| `src/web-app/` | The Vite site that builds the pages, with its nav manifest and tests |
| `plan/` | The current feature run, the archive of past runs, the changelog, and the backlog |
| `docs/` | Living docs about the system: components, dependencies, and decisions |
| `ravintio-zero/` | The installed RAVINTIO Zero pack |
| `ravintio-overrides/` | Repo-specific instructions and standards for the pack |
| `graphics/` | The RAVINTIO logo and the favicon set |

## Edit a page

1. Edit the Markdown file in `src/site-content/pages/`.
2. If you add a page, also add it to a section in `src/web-app/docs.manifest.json`.
3. Link other pages as `{slug}.md`. The build turns the link into `{slug}.html`.

## Run the site locally

```bash
cd src/web-app
npm ci
npm run dev
```

The `predev` script builds the pages into `src/web-app/docs/`, then Vite starts the dev server.

## Test

```bash
cd src/web-app
npm run build
npm test
```

The tests check these things:

- The nav sections and page order.
- That the earlier product brand appears nowhere outside the archive.
- That RAVINTIO is always in block capitals.
- That every internal link resolves.
- That the reference pages match the installed pack.
- That every sentence meets the style rules.

## Deploy

When a change merges to `main`, `.github/workflows/deploy.yml` builds the site and publishes it to GitHub Pages.

## Refresh the pack

If you work on Windows, run `refresh-ravintio-zero-dir.ps1`. It copies the pack from the sibling `zero` repo and reruns setup. On macOS or Linux, `update-ravintio-zero.local-only.sh` refreshes the pack from a local release folder.

## Licence

This repo uses the [Apache License 2.0](LICENSE.txt). It grants an explicit patent licence, and it lets you use the work in commercial products.
