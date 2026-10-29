# Purpose - web-app

`web-app` is the static Vite site that publishes the RAVINTIO docs to GitHub Pages. It owns the build, the layout, and the navigation. It doesn't own the page text.

## Why this component exists

The docs need a public site with no server runtime. `web-app` turns the Markdown pages from `site-content` into HTML and gives every page the same layout and nav.

## What it does

- Renders the homepage at `index.html`.
- Converts `src/site-content/pages/*.md` to HTML at build time with `scripts/build-docs.js`.
- Reads `docs.manifest.json` for the three nav sections, the page order, and the page titles.
- Adds the section nav, top nav, and previous and next links to every page.
- Shows the RAVINTIO logo and wordmark, the theme toggle, and the mobile menu.
- Loads `mermaid` only on pages that hold a diagram.
- Writes `public/sitemap-data.json` and `docs/sitemap.html`.

## What it does not do

- Write or edit page Markdown. `site-content` owns it.
- Accept user content at runtime.
- Expose an API.
