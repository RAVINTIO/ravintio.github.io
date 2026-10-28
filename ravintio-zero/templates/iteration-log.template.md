---
title: "Iteration Log - {{feature-id}}"
summary: "Execution log for the agent session."
status: "active"
version: "0.1.0"
---
# Iteration Log - {{feature-id}}

> **Audience:** The ship phase's build assessment (P4) and post-run technical review. This is NOT the PR changelog: the PR changelog (written at the start of ship) is the human-readable audit trail for PR reviewers.

**Skill:** [implement](../skills/ravintio-implement/SKILL.md) (or whichever agent completes the final documentation step)
**Date:** {{ISO-8601}}
**Wave:** {{wave-number}} (if waved)

## Iteration Steps Completed

| Phase | Status | Gate Result | Notes |
|-------|--------|-------------|-------|
| P0 - Discovery | {{pass/skip}} | Design confirmed: {{yes/no}} | {{coaching rounds count}} |
| P1 - Plan | {{pass/fail/skip}} | All artifacts produced: {{yes/no}} | {{n}} ADRs |
| P2 - Implement | {{pass/fail/skip}} | Implementation complete: {{yes/no}} | {{deviations count}} |
| P3 - Validate and Accept | {{pass/fail/blocked}} | CI clean and accepted: {{yes/no}} | {{self-correct cycles}} cycles |
| P4 - Ship | {{pass/fail/skip}} | Archived and PR raised: {{yes/no}} | |

## Requirement Changes During Run

| Change | Phase Active | Classification | Action Taken |
|--------|-------------|----------------|-------------|
| {{description}} | {{phase number}} | cosmetic / additive / contradictory | {{what was re-run}} |

## Self-Correct Log

{{what failed and how it was fixed - each attempt with the error and the fix}}

## Quirks

{{anything unusual noticed during the run - written to docs/quirks.md and component.yml}}

## Recommended Improvements

{{what should be reviewed before the PR - these are not blockers, but flagged for human attention}}

