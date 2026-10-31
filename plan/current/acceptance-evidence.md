# Acceptance evidence - 0000009-bug-fixes

## Checks

| Check | Result |
|-------|--------|
| Library audit | Pass. `vite` is the preferred bundler. No avoided library is installed. |
| Semantic coverage | Pass. Each of the 13 criteria maps to a test named with its requirement id. REQ-005 AC-1 and AC-2 also had browser checks. |
| Lint | No lint step declared for this stack |
| Typecheck | Pass (`tsc --noEmit`) |
| Tests | Pass, 38 of 38 (`npm test`) |
| Build | Pass (`npm run build`) |
| Dependency audit | Pass, 0 vulnerabilities (`npm audit`) |
| Self-correct cycles | 0 |

## Coverage

| Requirement | Criterion | Test |
|-------------|-----------|------|
| REQ-001 | AC-1, AC-2 | `tests/why-use-ravintio.test.mjs` |
| REQ-002 | AC-1, AC-2 | `tests/simplicity.test.mjs` |
| REQ-003 | AC-1, AC-2 | `tests/zero-overview.test.mjs` |
| REQ-004 | AC-1, AC-2 | `tests/copy-fixes.test.mjs` |
| REQ-005 | AC-1, AC-3 | `tests/mobile-nav.test.mjs`, plus browser checks |
| REQ-005 | AC-2 | Browser keyboard and accessibility tree check |
| REQ-006 | AC-1, AC-2 | `npm audit`, `npm run build`, and `npm test` |

## Security

No critical, high, or medium finding is open. `mermaid` moved to 12 with your approval, which cleared GHSA-238p-pmpm-9mq7 in `katex`. See `plan/current/security-report.md`.

## Execution

A browser drove the built site at 360 by 740 px and 1280 px. Every criterion is `verified`. A temporary diagram page confirmed that `mermaid` 12 renders in both themes. See `plan/current/verification-report.md`.

## Decisions you made in this run

- Approved `mermaid` 12 (`src/web-app/package.json`).
- Retired the 0.4.0 "eight principles" test (`src/web-app/tests/status-labels.test.mjs`).
- Exempted "as simple as the problem allows" from the `simple` check (`src/web-app/tests/style.test.mjs:20`).
