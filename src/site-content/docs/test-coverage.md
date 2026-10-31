# Test coverage - site-content

The tests live in `src/web-app/tests/` and run with `npm test` after `npm run build`.

| Test | Checks on these pages |
|------|----------------------|
| `status-labels.test.mjs` | Each tool's status label |
| `why-use-ravintio.test.mjs` | "Why use RAVINTIO" and the trimmed principles |
| `zero-overview.test.mjs` | `zero-overview` section order and "When Zero fits" |
| `simplicity.test.mjs` | The simplicity guidance on `zero-overview` and `pipeline` |
| `copy-fixes.test.mjs` | First-run step 2 and the copy review fixes |
| `reference-match.test.mjs` | Reference pages match the pack, both ways |
| `style.test.mjs` | Sentence length and banned words in prose |
| `capitals.test.mjs` | RAVINTIO in block capitals |
| `links.test.mjs` | Every internal link and anchor resolves |
| `brand-guard.test.mjs` | No earlier-brand text |

A human checks the pages against the private-content checklist at P3.
