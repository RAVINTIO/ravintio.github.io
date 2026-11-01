# Acceptance evidence - 0000016-site-regression-and-quality

## Checks

| Check | Result |
|-------|--------|
| Library audit | Pass. The pack lists Playwright as the preferred E2E framework. |
| Semantic coverage | Pass. Each of the 17 criteria maps to a test named with its requirement id. |
| Lint | No lint step declared for this stack |
| Typecheck | Pass (`tsc --noEmit`) |
| Content suite | Pass, 53 of 53 (`npm test`) |
| Regression suite | Pass, 33 passed and 1 skipped (`npm run test:e2e`). Three runs at 2.7 s, 2.3 s, and 2.4 s with `retries: 0`. |
| Build | Pass (`npm run build`) |
| Dependency audit | Pass, 0 vulnerabilities (`npm audit`) |
| Self-correct cycles | 1, for the fix-now review finding |

## Coverage

| Requirement | Criterion | Test |
|-------------|-----------|------|
| REQ-001 | AC-1 to AC-3 | `tests/e2e/page-health.spec.ts` |
| REQ-002 | AC-1 to AC-3 | `tests/e2e/interactive.spec.ts`. AC-3 reports a named skip, because no page holds a diagram. |
| REQ-003 | AC-1 to AC-3 | `tests/site-tests-workflow.test.mjs`, plus the first CI run on this pull request |
| REQ-004 | AC-1 | `tests/mcp-config.test.mjs` |
| REQ-005 | AC-1 to AC-3 | `tests/quality-review.test.mjs`, plus the review that ran in P3 |
| REQ-006 | AC-1 to AC-3 | `tests/e2e/first-frame.spec.ts` |

## Security

Overall risk is low. No critical, high, or medium finding is open. Three low findings remain:

- Workflow actions are pinned by tag, not SHA (S-001, filed as backlog 0000022).
- `npx` resolves Playwright MCP's dependencies at run time (S-002, accepted).
- The review's local-only browsing relies on the skill's instructions (S-003, accepted).

See `plan/current/security-report.md`.

## Execution

Playwright MCP drove the preview in Chromium at 390 px and 1280 px, in both themes. A script read `data-theme` when `<body>` first arrived. It matched the saved theme, or the system preference when nothing was saved. Fifteen criteria are `verified`. REQ-003 AC-1 and AC-2 are `not-verifiable` until this pull request runs `site-tests.yml`. See `plan/current/verification-report.md`.

## Site quality review

The first review covered 11 pages across five areas. It found one fix-now item, which this run fixed: `.playwright-mcp/` is now in `.gitignore`. It filed five backlog entries:

- 0000017: meta descriptions on doc pages.
- 0000018: a custom 404 page.
- 0000019: a `<main>` landmark on the homepage.
- 0000020: a wider text column on phones.
- 0000021: passive sentences on three pages.

See `plan/current/site-quality-report.md`.

## Decisions you made in this run

- Split the Framework docs out to backlog 0000014 (Framework is under major rework).
- Filed axe-core scans as backlog 0000015.
- Approved `@playwright/test` `1.64.1` and `@playwright/mcp` `0.0.83`, exact pins (`src/web-app/package.json`, `.mcp.json`).
- Reworded REQ-002 AC-3 to report a named skip when no page holds a diagram.

## After merge

- Add `Site tests` as a required check in the branch protection settings for `main`.
- Approve the `playwright` server from `.mcp.json` once, when a new session asks.
