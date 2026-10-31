# Security Report - bug-fixes

**Skill:** [validate-and-accept](../skills/ravintio-validate-and-accept/SKILL.md)
**Feature:** 0000009-bug-fixes
**Version:** 0.4.1

> It is advisory - no code changes are made. All findings require human review before action.

## Summary

**Overall Risk Assessment:** low
**Components Reviewed:** site-content, web-app
**Review Scope:** code review, dependency audit, secrets scan

No critical, high, or medium finding is open. `npm audit` reports 0 vulnerabilities.

## Findings

| ID | Severity | Category | Component | Description | Recommendation | Status |
|----|----------|----------|-----------|-------------|----------------|--------|
| S-001 | informational | injection | web-app | `scripts/build-docs.js:73` writes the current page title into the `<summary>`. The title comes from `docs.manifest.json` in the repo and passes through `escapeHtml`. | None | mitigated |
| S-002 | informational | injection | web-app | `src/page-list.ts` and `src/main.ts` set only the boolean `open` property. The diff adds no `innerHTML`, `eval`, or `document.write`. | None | mitigated |
| S-003 | low | dependency | web-app | `mermaid` moved from 11 to 12, a major version. No page holds a diagram today, so readers don't load it. `securityLevel: 'antiscript'` stays in `src/main.ts`. | Keep diagrams repo-authored | accepted |

## Dependency Audit

| Package | Current Version | Known CVEs | Severity | Action Required |
|---------|----------------|------------|----------|----------------|
| `mermaid` | 12.2.0 | none | none | none |
| `katex` (through `mermaid`) | 0.18.10 | none. GHSA-238p-pmpm-9mq7 fixed by the upgrade from 0.16.47. | none | none |
| `vite` | 7.3.7 | none | none | none |
| `marked` | 17 | none | none | none |

## Threat Model

| Threat | Attack Vector | Affected Component | Likelihood | Impact | Existing Mitigation | Gap |
|--------|--------------|-------------------|------------|--------|--------------------|----|
| Script injection through page text | A page or manifest edit adds markup | web-app | low | medium | Pages and manifest change only through reviewed PRs. Titles are escaped. | none |
| Vulnerable build dependency | A new advisory in the dependency tree | web-app | medium | low | `npm audit` at P3 on every run | No scheduled audit between runs |

## Risk Register Cross-Check

| Risk | Status |
|------|--------|
| R-001 `mermaid` 12 changes rendering | Mitigated. A test diagram rendered in both themes at P3. |
| R-002 copy breaks style rules | Mitigated. `style.test.mjs` passes. |
| R-003 readers miss the closed list | Open, low. The summary names the current page. |
| R-004 open list flashes on a phone | Open, low. Not seen in the browser check. |
| R-005 desktop nav unreachable | Mitigated. All ten links show at 1280 px. |
| R-006 Zero claim doesn't match the pack | Mitigated. The P2 reviewer checked each claim. |

## Recommendations

1. Keep diagrams repo-authored while `mermaid` runs with `antiscript`.
