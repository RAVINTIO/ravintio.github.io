---
title: "Risk Register - site-regression-and-quality"
summary: "Technical, operational, and security risks with their mitigations."
status: "active"
version: "0.1.0"
---
# Risk Register - site-regression-and-quality

**Skill:** [plan](../skills/ravintio-plan/SKILL.md) (updated by any agent that identifies a new risk)
**Feature:** 0000016-site-regression-and-quality
**Version:** 0.5.0
**Overall Risk Level:** low

## Risks

| ID | Category | Description | Likelihood | Impact | Mitigation | Status |
|----|----------|------------|------------|--------|-----------|--------|
| R-001 | technical | The first-frame test is flaky because paint timing varies | medium | medium | Check `data-theme` and the computed background at `DOMContentLoaded`, not a screenshot. AC-3 of REQ-003 runs the suite three times. | open |
| R-002 | operational | The first review finds more fix-now work than the run can hold | medium | medium | The 2-point cap stops and asks the human | open |
| R-003 | technical | A Playwright MCP upgrade renames tools and breaks the skill | low | low | Exact pin at `0.0.83`. A version change needs human approval. | open |
| R-004 | operational | Review entries flood the backlog | low | low | The duplicate check adds evidence to a matching entry | open |
| R-005 | security | The agent's browser reaches an outside site during the review | low | medium | The skill opens only the local preview origin. External links are checked by status, not opened in the MCP browser. | open |
| R-006 | security | `site-tests.yml` runs with write access it doesn't need | low | medium | `permissions: contents: read`. A test checks it. | open |
| R-007 | technical | The inline theme script blocks a future Content Security Policy that forbids inline scripts | low | low | ADR-004 records it. A future CSP adds the script's hash. | open |
| R-008 | technical | Chromium install adds time and the CI job passes 5 min | low | low | Install Chromium only, with `--with-deps`. AC-3 of REQ-003 measures the job. | open |

## Assumptions Logged as Risks

| ID | Assumption | Impact if Wrong | Status |
|----|-----------|----------------|--------|
| A-001 | The white flash comes from the deferred module script that sets `data-theme` | The inline script fixes nothing, and REQ-006 needs a new cause. The RED test checks this before the fix. | open |
| A-002 | Playwright MCP stays available in the P3 session | The review stops with a `Blocked:` line | open |
