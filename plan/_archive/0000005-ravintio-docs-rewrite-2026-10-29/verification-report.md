# Verification Report - 0000005-ravintio-docs-rewrite

## What ran

- `npm run build` in `src/web-app`, then `vite preview` on port 4179 serving `dist/`.
- A Playwright browser drove the preview at 1280 px and 360 px wide, in light and dark themes. The run stopped the server afterwards.

## Criteria

| Criterion | Method | Outcome | Observation |
|-----------|--------|---------|-------------|
| REQ-001 AC-1 overview pages present | Browser, `six-tools.html` | verified | Section nav shows RAVINTIO, Zero, Reference. RAVINTIO lists "What is RAVINTIO" then "The six tools". Page 1 names all eight principles (`status-labels.test.mjs`). |
| REQ-001 AC-2 status labels | Read built page and test | verified | Each of the six tools shows exactly its confirmed label |
| REQ-001 AC-3 no private content | Checklist scan of every page | verified by agent, human review pending | No implementation sequence, open question, threat model, proposed repo name, deployment pattern, maturity model, proposed output file, date, roadmap, or "coming soon" wording. No strategy text anywhere in the repo. |
| REQ-002 AC-1 Zero pages in order | Browser section nav | verified | Zero lists pages 3 to 7 in order. `aria-current` marks the open page. |
| REQ-002 AC-2 links resolve | `links.test.mjs` over `dist/` and browser clicks | verified | Every internal href and anchor resolves |
| REQ-002 AC-3 style rules | `style.test.mjs` | verified | No sentence reaches 25 words. No blocklisted word or mark. |
| REQ-003 AC-1 reference pages in order | Browser section nav | verified | Skills, Standards, Templates |
| REQ-003 AC-2 and AC-3 pack match | `reference-match.test.mjs` | verified | 16 skills, 18 standards, 45 templates, with no missing or extra items |
| REQ-004 AC-1 build and grouped nav | `npm run build`, browser | verified | Build exits 0. Every page shows three labelled sections with ten pages. |
| REQ-004 AC-2 no earlier brand | `brand-guard.test.mjs` | verified | No match in tracked files outside the allowlist, or in `dist/` |
| REQ-004 AC-3 brand capitals | `capitals.test.mjs`, browser | verified | Header wordmark, titles, and hero read RAVINTIO |
| NFR-001 accessibility | Contrast calculation, keyboard | verified | Light link text 6.07:1, dark 10.84:1, button text 6.35:1, logo graphic 3.15:1. The first Tab focuses a visible "Skip to content" link. Images carry alt text, or empty alt where the wordmark repeats the name. |
| NFR-002 page weight | File sizes in `dist/` | verified | About 26 to 30 KB per doc page with HTML, CSS, JS, and logo. `mermaid` didn't load on `six-tools.html`. |
| NFR-003 mobile layout | Browser at 360 px, all 12 pages | verified after one fix | `templates.html` first scrolled sideways because of a long code name in a heading. After the fix, no page scrolls. |
| NFR-004 build time | Local timing | verified locally | 2.5 s. CI timing becomes visible on the first deploy. |
| NFR-005 no private strategy | Repo-wide search | verified | No strategy file or text in the repo or its history |
