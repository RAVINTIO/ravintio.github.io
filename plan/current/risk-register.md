---
title: "Risk Register - bug-fixes"
summary: "Technical, operational, and security risks with their mitigations."
status: "active"
version: "0.1.0"
---
# Risk Register - bug-fixes

**Skill:** [plan](../skills/ravintio-plan/SKILL.md) (updated by any agent that identifies a new risk)
**Feature:** 0000009-bug-fixes
**Version:** 0.4.1
**Overall Risk Level:** low

## Risks

| ID | Category | Description | Likelihood | Impact | Mitigation | Status |
|----|----------|------------|------------|--------|-----------|--------|
| R-001 | technical | The `mermaid` update changes how the pipeline diagram renders | low | medium | P3 browser check of the `pipeline` page | open |
| R-002 | technical | New copy breaks the sentence-length or blocklist rules in `style.test.mjs` | medium | low | `style.test.mjs` runs in every P2 unit. Agreed copy that fails is reported, not rewritten silently. | open |
| R-003 | operational | Readers on a phone miss the closed page list and can't find other pages | low | low | The summary names the current page and shows the native disclosure marker | open |
| R-004 | technical | `main.ts` closes the disclosure after first paint, so the open list flashes on a phone | medium | low | Close it in a module script that runs before images load. P3 browser check at 360 px. | open |
| R-005 | compliance | Hiding the summary at desktop widths leaves the nav unreachable by keyboard if CSS hides the list | low | medium | CSS hides only the `<summary>`. The `<details>` stays open at 900 px and above. AC-3 checks it. | open |
| R-006 | technical | A claim in the new Zero copy doesn't match the installed pack | low | medium | Check each claim against `ravintio-zero/` skills and standards during P2 | open |

## Assumptions Logged as Risks

| ID | Assumption | Impact if Wrong | Status |
|----|-----------|----------------|--------|
| A-001 | `npm audit fix` within current majors changes no site behaviour | A build or rendering regression, caught by `npm test` and the P3 browser check | open |
