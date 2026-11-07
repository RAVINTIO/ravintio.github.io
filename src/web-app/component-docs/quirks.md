# Quirks - web-app

## Q-001: Component docs live in `component-docs/`

`src/web-app/docs/` holds the generated HTML pages. The component docs sit in `component-docs/` so they stay apart from build output.

## Q-002: Generated pages aren't committed

`scripts/build-docs.js` writes `docs/*.html` and `public/sitemap-data.json` on every build. Both paths are in `.gitignore`. Run `npm run build` or `npm run dev` to create them.

## Q-003: Theme toggle reloads diagram pages

Mermaid draws each diagram once. If a page holds a diagram, the theme toggle reloads the page so the diagram redraws in the new theme. Pages without diagrams don't reload.

## Q-004: Adding a page takes two edits

1. Add `{slug}.md` to `src/site-content/pages/`.
2. Add the page to a section in `docs.manifest.json`, with a `file`, a `title`, and a `description` of 50 to 160 characters.

If a manifest entry has no page file or no description, the build fails. If a page file has no manifest entry, the build warns and skips it.

## Q-005: Favicon and asset paths are relative

GitHub Pages serves the site at the org root, `https://ravintio.github.io`. Every icon and asset path is relative, so the site also works under a path, such as a fork served at `/{repo}/`. The 404 page is the exception. See Q-009.

## Q-006: The Playwright suite tests an existing build

`npm run test:e2e` serves `dist/` with `vite preview` on port 4173. It doesn't build. Run `npm run build` first.

## Q-007: The theme logic lives in two places

An inline script at the top of `<head>` sets `data-theme` before first paint. `main.ts` reads that value and owns the toggle. A change to how the theme is chosen needs both places (0000016 ADR-004).

## Q-008: The dev and preview servers have no SPA fallback

`vite.config.ts` sets `appType: 'mpa'`. A missing page returns 404 locally, as it does on GitHub Pages, so the link check catches it. The preview server also serves `dist/404.html` with that status, through the `github-pages-not-found` plugin in `vite.config.ts`. Vite 7 preview has no 404 page support of its own.

## Q-009: The 404 page assumes the domain root

GitHub Pages serves `404.html` for a missing path at any depth. The page sets `<base href="/">`, so its relative assets and links resolve from the domain root (0000027 ADR-003). A fork served under `/{repo}/` needs a matching base.

## Q-010: Code blocks take keyboard focus

`build-docs.js` writes `tabindex="0"` on every code `<pre>`. A wide block scrolls sideways, and the focus lets keyboard users scroll it (axe rule `scrollable-region-focusable`). Mermaid blocks don't take focus.
