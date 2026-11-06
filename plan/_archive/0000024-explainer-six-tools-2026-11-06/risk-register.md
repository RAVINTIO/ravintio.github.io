---
title: "Risk Register - explainer-six-tools"
summary: "Technical, operational, and security risks with their mitigations."
status: "active"
version: "0.1.0"
---
# Risk Register - explainer-six-tools

**Skill:** [plan](../skills/ravintio-plan/SKILL.md) (updated by any agent that identifies a new risk)
**Feature:** 0000024-explainer-six-tools
**Version:** 0.6.0
**Overall Risk Level:** low

## Risks

| ID | Category | Description | Likelihood | Impact | Mitigation | Status |
|----|----------|------------|------------|--------|-----------|--------|
| R-001 | technical | The regex voice check flags adjective uses such as "are merged", so the allowlist grows. | medium | low | Keep each allowlist entry with a comment. The check matches only a closed list of irregular participles plus words ending in "ed". | open |
| R-002 | compliance | The rewrite claims features for the four in-design tools. | low | medium | REQ-001 requires active aims for in-design tools. The P3 quality review reads the page. | open |
| R-003 | technical | Changing the anchor to `#why-ravintio` breaks a link. | medium | low | `links.test.mjs` checks anchors. REQ-001 moves every link. | open |
| R-004 | technical | Two units rebuild `dist/` and use preview port 4173 at once and corrupt each other's test run. | medium | medium | The concurrency plan runs every unit in sequence. | mitigated |
| R-005 | operational | Equal-length entries read as padding for in-design tools. | medium | low | The 1.5 ratio leaves room. Entries stay short. | open |

## Assumptions Logged as Risks

| ID | Assumption | Impact if Wrong | Status |
|----|-----------|----------------|--------|
| A-001 | Dropping the ten Zero-style bullets loses no content readers need, because the Zero overview covers Zero's benefits. | Readers lose points such as "No lock-in". A follow-up moves them to the Zero overview. | open |
| A-002 | The homepage meta description stays as it is and differs from every page description. | REQ-002 AC-2 fails and the homepage needs a new description. | open |
