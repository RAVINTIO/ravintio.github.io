# Test coverage - web-app

Two suites run from `src/web-app`, after `npm run build`. The content suite runs with `npm test` on the Node test runner. The regression suite runs with `npm run test:e2e` in Chromium. `.github/workflows/site-tests.yml` runs both on each pull request.

## Content suite

| Test | Requirement | Checks |
|------|-------------|--------|
| `nav.test.mjs` | REQ-001 to REQ-004 | Manifest sections and order, and the section nav on every built page |
| `brand-guard.test.mjs` | REQ-004 | No earlier-brand text in tracked files or `dist/` |
| `capitals.test.mjs` | REQ-004 | RAVINTIO in block capitals in pages and built HTML |
| `links.test.mjs` | REQ-002 | Every internal link and anchor in `dist/` resolves |
| `style.test.mjs` | REQ-002 | Sentence length and banned words on every page |
| `status-labels.test.mjs` | REQ-001 | Tool status labels and no dated promises |
| `reference-match.test.mjs` | REQ-003 | Reference pages match the pack |
| `why-use-ravintio.test.mjs` | 0000009 REQ-001 | "Why use RAVINTIO" list, removed name section, and trimmed principles |
| `zero-overview.test.mjs` | 0000009 REQ-003 | `zero-overview` section order and "When Zero fits" |
| `simplicity.test.mjs` | 0000009 REQ-002 | Simplicity section and the P2 simplicity sentence |
| `copy-fixes.test.mjs` | 0000009 REQ-004 | First-run step 2 runs on a fresh setup, plus four copy fixes |
| `mobile-nav.test.mjs` | 0000009 REQ-005 | Page-list disclosure markup, desktop CSS, and `syncPageList` behaviour at each breakpoint |
| `mcp-config.test.mjs` | 0000016 REQ-004 | `.mcp.json` pins `@playwright/mcp` at `0.0.83` |
| `site-tests-workflow.test.mjs` | 0000016 REQ-003 | `site-tests.yml` trigger, permissions, step order, and report upload |
| `quality-review.test.mjs` | 0000016 REQ-005 | The quality review skill and repo instruction hold the areas, targets, rule, cap, and duplicate check |

## Regression suite

| Test | Requirement | Checks |
|------|-------------|--------|
| `e2e/page-health.spec.ts` | 0000016 REQ-001 | Each page returns 200 with no console errors, links and anchors resolve, and no sideways scroll at 390 px |
| `e2e/interactive.spec.ts` | 0000016 REQ-002 | Theme toggle and persistence, the page list at 390 px and 1280 px, and Mermaid diagrams, with a named skip when no page holds one |
| `e2e/first-frame.spec.ts` | 0000016 REQ-006 | The first frame matches a saved theme or the system preference |

Requirement IDs without a prefix belong to feature 0000005.

Keyboard use and colour contrast get a manual check in the P3 quality review.
