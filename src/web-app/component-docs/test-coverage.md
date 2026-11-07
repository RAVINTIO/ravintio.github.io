# Test coverage - web-app

Two suites run from `src/web-app`, after `npm run build`. The content suite runs with `npm test` on the Node test runner. The regression suite runs with `npm run test:e2e` in Chromium. `.github/workflows/site-tests.yml` runs both on each pull request.

## Content suite

| Test | Requirement | Checks |
|------|-------------|--------|
| `nav.test.mjs` | REQ-001 to REQ-004 | Manifest sections and order, and the section nav on every built page |
| `brand-guard.test.mjs` | REQ-004 | No earlier-brand text in tracked files or `dist/` |
| `capitals.test.mjs` | REQ-004 | RAVINTIO in block capitals in pages and built HTML |
| `links.test.mjs` | REQ-002 | Every internal link and anchor in `dist/` resolves |
| `style.test.mjs` | REQ-002, REQ-003 | Sentence length and banned words in prose on every page. Passive voice in prose and table cells, including negated and adverb forms. An allowlist holds adjective uses. |
| `status-labels.test.mjs` | REQ-001 | Tool status labels and no dated promises |
| `reference-match.test.mjs` | REQ-003 | Reference pages match the pack |
| `why-use-ravintio.test.mjs` | 0000009 REQ-001, 0000024 REQ-001 | "Why RAVINTIO?" list, removed name section, and trimmed principles |
| `explainer.test.mjs` | 0000024 REQ-001 | Purpose-led opening, a tool-free "Why RAVINTIO?", balanced entries for the six tools, and the hero subtitle and homepage meta description |
| `meta-descriptions.test.mjs` | 0000024 REQ-002 | One meta description per built page that matches the manifest, unique descriptions of 50 to 160 characters, and the build check for a missing one |
| `zero-overview.test.mjs` | 0000009 REQ-003 | `zero-overview` section order and "When Zero fits" |
| `simplicity.test.mjs` | 0000009 REQ-002 | Simplicity section and the P2 simplicity sentence |
| `copy-fixes.test.mjs` | 0000009 REQ-004 | First-run step 2 runs on a fresh setup, plus four copy fixes |
| `mobile-nav.test.mjs` | 0000009 REQ-005 | Page-list disclosure markup, desktop CSS, and `syncPageList` behaviour at each breakpoint |
| `mcp-config.test.mjs` | 0000016 REQ-004 | `.mcp.json` pins `@playwright/mcp` at `0.0.83` |
| `site-tests-workflow.test.mjs` | 0000016 REQ-003, 0000027 REQ-005 | `site-tests.yml` trigger, permissions, step order, and report upload. Every action in `site-tests.yml` and `deploy.yml` pinned by full SHA with a tag comment. |
| `org-link.test.mjs` | 0000027 REQ-006 | Header and footer code links on every built page point to the RAVINTIO organisation, with the label "RAVINTIO on GitHub" |
| `not-found.test.mjs` | 0000027 REQ-002 | `dist/404.html` has the root base, the site header, one `<h1>`, links home and to the sitemap, and a description |
| `ops-table-cell.test.mjs` | 0000027 REQ-007 | The `ravintio.yml` row on the project operations page names the actor |
| `quality-review.test.mjs` | 0000016 REQ-005 | The quality review skill and repo instruction hold the areas, targets, rule, cap, and duplicate check |

## Regression suite

| Test | Requirement | Checks |
|------|-------------|--------|
| `e2e/page-health.spec.ts` | 0000016 REQ-001, 0000027 REQ-003, REQ-004 | Each page returns 200 with no console errors, links and anchors resolve, and no sideways scroll at 390 px. Each page has one `<main>`, and the homepage skip link targets it. Doc page text is at least 330 px wide at 390 px. |
| `e2e/not-found.spec.ts` | 0000027 REQ-002 | The 404 page at a nested missing path returns 404 and loads its stylesheet and script |
| `e2e/axe.spec.ts` | 0000027 REQ-001 | An axe-core WCAG 2.2 AA scan of every page in light and dark. Serious and critical violations fail. The global teardown in `e2e/axe-report.ts` writes the rest to `test-results/axe-report.json`. |
| `e2e/interactive.spec.ts` | 0000016 REQ-002, 0000027 REQ-003 | Theme toggle and persistence, the page list at 390 px and 1280 px, and Mermaid diagrams, with a named skip when no page holds one. The skip link moves focus to `#content`. |
| `e2e/first-frame.spec.ts` | 0000016 REQ-006 | The first frame matches a saved theme or the system preference |

Requirement IDs without a prefix belong to feature 0000005.

`pages.ts` lists the homepage, `/404.html`, `/docs/sitemap.html`, and every manifest page.

The axe scan checks colour contrast in both themes. Keyboard use still gets a manual check in the P3 quality review, which also reads `test-results/axe-report.json`.
