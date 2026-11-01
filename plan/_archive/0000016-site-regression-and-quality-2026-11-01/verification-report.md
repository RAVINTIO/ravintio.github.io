# Verification Report - 0000016-site-regression-and-quality

## What ran

1. `npm run build` in `src/web-app`, then `npx vite preview --port 4173 --strictPort` on localhost.
2. Playwright MCP drove Chromium at 390 by 844 px and 1280 by 800 px, in both themes and both system colour schemes.
3. A script recorded `data-theme` when `<body>` first entered the document. The module script can't have run at that point.
4. The node suites read `.mcp.json`, `site-tests.yml`, and the review skill.
5. The site quality review ran from the installed `site-quality-review` skill.
6. The preview server and the MCP browser stopped after the checks.

## Criteria

| Requirement | Criterion | Method | Outcome | Evidence |
|-------------|-----------|--------|---------|----------|
| REQ-001 | AC-1 | `npm run test:e2e`, plus the review's page pass | verified | All 11 pages loaded with status 200. The only console error in the MCP log came from a deliberate request for a missing page. |
| REQ-001 | AC-2 | `npm run test:e2e` with a broken link injected into the build | verified | The link test passes on the real build. With `./missing-page.html` injected into `pipeline.html`, it fails with `status 404`. |
| REQ-001 | AC-3 | Browser at 390 px, dark theme | verified | `scrollWidth` equals the viewport width on all 11 pages |
| REQ-002 | AC-1 | Browser click on `#theme-toggle` | verified | On `pipeline.html` the theme went from `light` to `dark`. After a reload, `data-theme` and the saved value both held `dark`. |
| REQ-002 | AC-2 | Browser at 390 px and 1280 px | verified | Closed on load at 390 px, open after a click on the summary, and open at 1280 px |
| REQ-002 | AC-3 | `npm run test:e2e` output | verified | No page holds a Mermaid diagram. The test reports as skipped and prints `no page holds a Mermaid diagram`. |
| REQ-003 | AC-1 | `site-tests.yml` content test | not-verifiable | The workflow runs on a pull request, and P4 raises it. P4 records the first run's result. |
| REQ-003 | AC-2 | `site-tests.yml` content test | not-verifiable | A real failure needs a failing pull request. The content test confirms the `if: failure()` upload of `playwright-report`. |
| REQ-003 | AC-3 | Three local runs, plus the CI job | verified locally | Three runs passed with `retries: 0`, at 2.7 s, 2.3 s, and 2.4 s. The CI duration comes from the first pull request run. |
| REQ-004 | AC-1 | `.mcp.json` parse test | verified | One `playwright` server running `npx @playwright/mcp@0.0.83`, with no range or `latest` tag. A new session loads it after a one-time approval. |
| REQ-005 | AC-1 | Ran the review in this P3 | verified | The installed skill ran after the suite passed. `custom-003` is in the repo instructions. |
| REQ-005 | AC-2 | Read the written report | verified | `site-quality-report.md` holds all five areas, each with its target and findings |
| REQ-005 | AC-3 | Observed the sorting during the review | verified | One fix-now finding at 1 point, under the cap, was fixed. Five backlog findings were filed after a duplicate search found no match. |
| REQ-006 | AC-1 | Browser, dark saved | verified | `data-theme` was `dark` when `<body>` arrived, on `/` and `pipeline.html`. The body background was `rgb(2, 6, 23)`. |
| REQ-006 | AC-2 | Browser, light saved, dark system preference | verified | `data-theme` was `light` when `<body>` arrived on both pages |
| REQ-006 | AC-3 | Browser, nothing saved, dark system preference | verified | `data-theme` was `dark` when `<body>` arrived on both pages |
