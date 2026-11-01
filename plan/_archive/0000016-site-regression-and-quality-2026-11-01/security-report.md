# Security Report - site-regression-and-quality

**Skill:** [validate-and-accept](../skills/ravintio-validate-and-accept/SKILL.md)
**Feature:** 0000016-site-regression-and-quality
**Version:** 0.5.0

> It is advisory - no code changes are made. All findings require human review before action.

## Summary

**Overall Risk Assessment:** low
**Components Reviewed:** web-app, repo-level config (`.mcp.json`, `site-tests.yml`, `ravintio-overrides/`)
**Review Scope:** code review, dependency audit, threat model

No critical, high, or medium finding. The site stays static, with no backend, sign-in, or stored user data.

## Findings

| ID | Severity | Category | Component | Description | Recommendation | Status |
|----|----------|----------|-----------|-------------|----------------|--------|
| S-001 | low | dependency | repo-level | `.github/workflows/site-tests.yml` pins `actions/checkout@v5`, `actions/setup-node@v5`, and `actions/upload-artifact@v4` by tag, not commit SHA. `deploy.yml` does the same. | Pin all workflow actions by SHA in one later change | open |
| S-002 | low | dependency | repo-level | `.mcp.json` runs `npx @playwright/mcp@0.0.83`. The package version is exact, but `npx` resolves its own dependencies at run time without a lockfile. | Accept. The exact pin limits drift, and the server runs only in local agent sessions. | accepted |
| S-003 | low | config | repo-level | Playwright MCP offers `browser_run_code_unsafe`, which runs code with Node rights in the MCP server. The review skill tells the agent to open only `http://localhost:4173`. Nothing enforces that. | Accept for a local, human-supervised tool. Claude Code's permission prompts still apply to each MCP call. | accepted |
| S-004 | informational | injection | web-app | The inline theme script in `index.html` and `scripts/build-docs.js` reads `localStorage`. It accepts only `light` or `dark` and writes only `data-theme`. | None | mitigated |
| S-005 | informational | config | repo-level | `site-tests.yml` uses `pull_request`, not `pull_request_target`, with `permissions: contents: read`. A fork's pull request gets no secrets and no write token. | None | mitigated |

## Dependency Audit

| Package | Current Version | Known CVEs | Severity | Action Required |
|---------|----------------|------------|----------|----------------|
| `@playwright/test` | 1.64.1 | none | none | none |
| `playwright`, `playwright-core` | 1.64.1 | none | none | none |
| All `src/web-app` packages | lockfile | none (`npm audit`: 0 vulnerabilities) | none | none |

## Threat Model

| Threat | Attack Vector | Affected Component | Likelihood | Impact | Existing Mitigation | Gap |
|--------|--------------|-------------------|------------|--------|--------------------|----|
| The review browser reaches an outside site | The agent follows an external link in the MCP browser | repo-level | low | medium | The skill limits navigation to the preview origin. Claude Code prompts for MCP calls. | No technical block (S-003) |
| A pull request workflow leaks a token | A fork's pull request changes the workflow | repo-level | low | medium | `pull_request` trigger and read-only permissions | none |
| A tampered action tag | An upstream action's tag moves | repo-level | low | medium | GitHub-owned actions only | SHA pinning (S-001) |
| A stored theme value injects markup | A crafted `localStorage` value | web-app | low | low | Exact-value check in the inline script | none |

## Risk register cross-check

| Risk | Status |
|------|--------|
| R-005 review browser reaches an outside site | Open, as S-003 |
| R-006 workflow write access | Mitigated, as S-005 |
| R-007 inline script and a future CSP | Open, no CSP today |

## Recommendations

Ordered by priority (critical first):

1. Pin the workflow actions by commit SHA (S-001).
