# Component Registry

Last updated: 0000009-bug-fixes

---

## Components

| ID | Type | Purpose | Stack | Status |
|----|------|---------|-------|--------|
| `site-content` | content | The Markdown pages that explain RAVINTIO and teach RAVINTIO Zero | Markdown | active |
| `web-app` | static site | Builds the pages into the site, with sectioned nav, logo, and tests | Vite 7, TypeScript 5.9, vanilla CSS, marked 17, mermaid 12, Node test runner | active |

---

## site-content

**Path:** `src/site-content/`
**Manifest:** [component.yml](../src/site-content/component.yml)
**Docs:** [data contract](../src/site-content/docs/data-contract.md) and the other files in `src/site-content/docs/`

**Pages:**

| Section | File | Title |
|---------|------|-------|
| RAVINTIO | `what-is-ravintio.md` | What is RAVINTIO |
| RAVINTIO | `six-tools.md` | The six tools |
| Zero | `zero-overview.md` | Zero overview |
| Zero | `install-zero.md` | Install Zero |
| Zero | `first-run.md` | Your first run |
| Zero | `pipeline.md` | The pipeline |
| Zero | `project-operations.md` | Project operations |
| Reference | `skills.md` | Skills |
| Reference | `standards.md` | Standards |
| Reference | `templates.md` | Templates |

**Not responsible for:** HTML generation, navigation, or styling.

---

## web-app

**Path:** `src/web-app/`
**Manifest:** [component.yml](../src/web-app/component.yml)
**Docs:** [purpose](../src/web-app/component-docs/purpose.md) and the other files in `src/web-app/component-docs/`

**Source files:**
- `scripts/build-docs.js` turns the pages into HTML and writes the nav, sitemap, and pagination.
- `docs.manifest.json` holds the sections, page order, and titles.
- `vite.config.ts` reads the manifest for its build inputs.
- `src/main.ts` runs the theme toggle, the mobile menu, and on-demand diagrams.
- `src/style.css` holds the styles and the teal brand colours.
- `tests/*.test.mjs` hold the site tests, run with `npm test`.

**Not responsible for:** page text.
