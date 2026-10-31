# Verification Report - 0000009-bug-fixes

## What ran

1. `npm run build` in `src/web-app`, then `npx vite preview --port 4173` on localhost.
2. Playwright drove Chromium at 360 by 740 px and 1280 by 800 px.
3. The preview server stopped after the checks.

## Criteria

| Requirement | Criterion | Method | Outcome | Evidence |
|-------------|-----------|--------|---------|----------|
| REQ-001 | AC-1 | Browser and built HTML | verified | "Why use RAVINTIO" is the first H2 on `what-is-ravintio`, with ten bullets. No "The name" section. |
| REQ-001 | AC-2 | Built HTML | verified | "Shared design principles" holds three bullets |
| REQ-002 | AC-1 | Built HTML | verified | "How Zero keeps solutions simple" holds Discovery, Plan, Implement, and Standards |
| REQ-002 | AC-2 | Built HTML | verified | The P2 section of `pipeline` holds the simplicity sentence |
| REQ-003 | AC-1 | Built HTML | verified | H2 order starts "Why use Zero", "How a run flows", and ends "Terms" |
| REQ-003 | AC-2 | Built HTML | verified | "When Zero fits" present. No benchmark line. |
| REQ-004 | AC-1 | Script run | verified | `copy-fixes.test.mjs` runs the step 2 commands in a fresh temporary folder. Both exit 0 and the brief exists. |
| REQ-004 | AC-2 | Browser | verified | The homepage subtitle reads the agreed text. Install, first-run, and six-tools match. |
| REQ-005 | AC-1 | Browser at 360 by 740 px | verified | On all ten pages the list is closed and the summary names the page. The H1 bottom sits at 271 to 319 px. No horizontal scroll. |
| REQ-005 | AC-2 | Browser keyboard | verified | The summary takes focus on the sixth Tab. Enter opens the list and Space toggles it. The accessibility tree reports `DisclosureTriangle` with `expanded` true or false to match. |
| REQ-005 | AC-3 | Browser at 1280 px | verified | The list is open and sticky. The summary has `display: none`, and all ten links show left of the content. Widening from 360 px to 1280 px reopens the list. |
| REQ-006 | AC-1 | `npm audit` | verified | 0 vulnerabilities |
| REQ-006 | AC-2 | `npm run build`, `npm test` | verified | Build passes. 38 of 38 tests pass. |

## Extra check

No page holds a diagram. To cover R-001, a temporary copy of `pipeline.html` in `dist/` held one flowchart. `main.ts` loaded `mermaid` 12 and drew three nodes and two edges in both themes, with no page errors. The copy was then deleted.
