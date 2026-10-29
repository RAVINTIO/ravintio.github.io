# Acceptance evidence - 0000005-ravintio-docs-rewrite

## Checks

| Check | Result |
|-------|--------|
| Library audit | Pass. `vite` is the preferred bundler. No avoided library is installed. |
| Semantic coverage | Pass. Each of the 12 acceptance criteria maps to a test named with its requirement id, except REQ-001 AC-3, which is a human checklist. |
| Lint | No lint step declared for this stack |
| Typecheck | Pass (`tsc --noEmit`) |
| Tests | Pass, 21 of 21 (`npm test`) |
| Build | Pass (`npm run build`, 2.5 s locally) |
| Self-correct cycles | 1 (mobile overflow on `templates.html`, fixed in `src/web-app/src/style.css`) |

## Coverage

| Requirement | Criterion | Test |
|-------------|-----------|------|
| REQ-001 | AC-1 | `tests/nav.test.mjs`, `tests/status-labels.test.mjs` |
| REQ-001 | AC-2 | `tests/status-labels.test.mjs` |
| REQ-001 | AC-3 | Human checklist, plus `tests/status-labels.test.mjs` for dates and roadmap wording |
| REQ-002 | AC-1 | `tests/nav.test.mjs` |
| REQ-002 | AC-2 | `tests/links.test.mjs` |
| REQ-002 | AC-3 | `tests/style.test.mjs` |
| REQ-003 | AC-1 | `tests/nav.test.mjs` |
| REQ-003 | AC-2, AC-3 | `tests/reference-match.test.mjs` |
| REQ-004 | AC-1 | `tests/nav.test.mjs` |
| REQ-004 | AC-2 | `tests/brand-guard.test.mjs` |
| REQ-004 | AC-3 | `tests/capitals.test.mjs` |

## Security

No critical or high finding is open. Two medium advisories sit in `mermaid` and its `dompurify` dependency, which render only repo-authored diagrams. Backlog `0000007` tracks the upgrade. See `plan/current/security-report.md`.

## Execution

A browser drove the built site at 1280 px and 360 px, in both themes. Every criterion is `verified`. REQ-001 AC-3 still needs your review against the private-content checklist. See `plan/current/verification-report.md`.

## Before you merge

1. Rename the GitHub repo to `ravintio-docs`.
2. Confirm `github.com/RAVINTIO/ravintio-framework` is public, because the site labels Framework "Available".
3. Review pages 1 and 2 against the private-content checklist.
