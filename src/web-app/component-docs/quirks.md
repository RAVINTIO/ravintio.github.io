# Quirks - web-app

## Q-001: Component docs live in `component-docs/`

`src/web-app/docs/` holds the generated HTML pages. The component docs sit in `component-docs/` so they stay apart from build output.

## Q-002: Generated pages aren't committed

`scripts/build-docs.js` writes `docs/*.html` and `public/sitemap-data.json` on every build. Both paths are in `.gitignore`. Run `npm run build` or `npm run dev` to create them.

## Q-003: Theme toggle reloads diagram pages

Mermaid draws each diagram once. If a page holds a diagram, the theme toggle reloads the page so the diagram redraws in the new theme. Pages without diagrams don't reload.

## Q-004: Adding a page takes two edits

1. Add `{slug}.md` to `src/site-content/pages/`.
2. Add the page to a section in `docs.manifest.json`.

If a manifest entry has no page file, the build fails. If a page file has no manifest entry, the build warns and skips it.

## Q-005: Favicon and asset paths are relative

GitHub Pages serves the site under `/ravintio-docs/`. Every icon and asset path is relative, so it works under any base path.
