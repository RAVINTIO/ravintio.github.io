# Security Report - explainer-six-tools

**Skill:** [validate-and-accept](../skills/ravintio-validate-and-accept/SKILL.md)
**Feature:** 0000024-explainer-six-tools
**Version:** 0.6.0

> It is advisory - no code changes are made. All findings require human review before action.

## Summary

**Overall Risk Assessment:** low
**Components Reviewed:** site-content, web-app
**Review Scope:** code review, dependency audit

## Findings

| ID | Severity | Category | Component | Description | Recommendation | Status |
|----|----------|----------|-----------|-------------|----------------|--------|
| S-001 | informational | injection | web-app | `scripts/build-docs.js:98` renders each manifest `description` into an HTML attribute. `escapeHtml` in `scripts/manifest.js:3` escapes it, and the manifest is a tracked repo file, not user input. | None | mitigated |
| S-002 | informational | config | web-app | `scripts/manifest.js:12` fails the build on a missing description, so a malformed manifest can't publish a page with an empty `<head>` field. | None | mitigated |

No critical, high, medium, or low finding. The run adds no dependency, workflow, permission, or secret. A scan of the diff found no credential.

## Dependency Audit

| Package | Current Version | Known CVEs | Severity | Action Required |
|---------|----------------|------------|----------|----------------|
| All `src/web-app` packages | unchanged by this run | none (`npm audit`: 0 vulnerabilities) | none | none |

## Risk register cross-reference

| Risk | State |
|------|-------|
| R-001 voice check allowlist grows | open. The allowlist holds two phrases. |
| R-002 overclaiming in-design tools | mitigated. The improvement review removed "will" promises. |
| R-003 anchor change breaks a link | mitigated. The click-through and `links.test.mjs` pass. |
| R-004 shared `dist/` and port | mitigated. All units ran in sequence. |
| R-005 padded entries | open. Entries run 33 to 41 words. |

## Top actions before production

None.
