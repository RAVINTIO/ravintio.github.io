# Test coverage - web-app

The tests run with `npm test` from `src/web-app`, after `npm run build`. They use the Node test runner.

| Test | Requirement | Checks |
|------|-------------|--------|
| `nav.test.mjs` | REQ-001 to REQ-004 | Manifest sections and order, and the section nav on every built page |
| `brand-guard.test.mjs` | REQ-004 | No earlier-brand text in tracked files or `dist/` |
| `capitals.test.mjs` | REQ-004 | RAVINTIO in block capitals in pages and built HTML |
| `links.test.mjs` | REQ-002 | Every internal link and anchor in `dist/` resolves |
| `style.test.mjs` | REQ-002 | Sentence length and banned words on every page |
| `status-labels.test.mjs` | REQ-001 | Tool status labels, principles, and no dated promises |
| `reference-match.test.mjs` | REQ-003 | Reference pages match the pack |

The tests read files and built HTML. No browser test runs. Keyboard use and colour contrast get a manual check at P3.
