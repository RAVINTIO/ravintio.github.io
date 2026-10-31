# Test coverage - web-app

The tests run with `npm test` from `src/web-app`, after `npm run build`. They use the Node test runner.

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

Requirement IDs without a prefix belong to feature 0000005.

The tests read files and built HTML. No browser test runs. Keyboard use, colour contrast, and the disclosure at 360 px get a manual check at P3.
