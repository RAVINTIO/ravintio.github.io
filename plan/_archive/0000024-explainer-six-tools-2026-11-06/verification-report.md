# Verification report - 0000024-explainer-six-tools

## What ran

- `npm run build` in `src/web-app`, then `npx vite preview --port 4173 --strictPort`.
- Playwright MCP drove Chromium against `http://localhost:4173` at 390 px and 1280 px, in both themes.
- The preview server stopped at the end of the review.

## Per criterion

| Criterion | Method | Outcome | Evidence |
|-----------|--------|---------|----------|
| REQ-001 AC-1 | Browser read of the built explainer | verified | The opening paragraph names "visibility and governance over agentic software development". The first H2 is "Why RAVINTIO?". The six tool names appear only from the second H2 onwards. |
| REQ-001 AC-2 | Browser read of the H3 list, word counts from the source | verified | Six H3 entries in the order Zero, Framework, Accept, Qualify, Insight, Unbound. Entries run 33 to 41 words, a ratio of 1.24. |
| REQ-001 AC-3 | Browser read of the homepage | verified | The subtitle reads "Six tools for visibility and governance over agentic software development." It names no single tool. The homepage meta description now matches (C-001). |
| REQ-001 anchor | Click-through | verified | The Zero overview link to `what-is-ravintio.html#why-ravintio` lands on the "Why RAVINTIO?" heading. |
| REQ-002 AC-1 | Browser fetch of every built page | verified | Each of the ten manifest pages and the sitemap holds exactly one meta description. The explainer's matches its manifest value. |
| REQ-002 AC-2 | Browser fetch, length and uniqueness | verified | Manifest descriptions run 105 to 116 characters, all unique. The sitemap's runs 68 characters. |
| REQ-003 AC-1 | Browser search of rendered text | verified | No "is designed", "is meant", "are checked", "is staged", "is shared", or "is confirmed" phrase remains on the four edited pages. |
| REQ-003 AC-2 | Command: `npm test` | verified | The voice check runs over every page, prose and tables, with 0 hits outside the two-phrase allowlist. It flags "The file is checked by the hook." and "It is not meant to ship." |

No criterion is `not-verifiable`.
