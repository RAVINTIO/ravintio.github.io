---
title: "Iteration Log - 0000024-explainer-six-tools"
summary: "Execution log for the agent session."
status: "active"
version: "0.1.0"
---

# Changelog (0000024-explainer-six-tools, 06 Nov 2026)

**Feature:** Rebalance the explainer to all six tools
**Version:** 0.6.0
**PR:** [#26](https://github.com/RAVINTIO/ravintio.github.io/pull/26)

## What changed

- The explainer `what-is-ravintio.md` now opens with the shared purpose: visibility and governance over agentic software development.
- A tool-free "Why RAVINTIO?" section replaces the ten Zero-style "Why use RAVINTIO?" bullets.
- A new "The six tools" section gives each tool an entry of 33 to 41 words. The four in-design tools state aims, not features.
- The homepage subtitle and meta description name the shared purpose and no single tool.
- Each doc page now carries a unique meta description from a new `description` field in `docs.manifest.json`. The build fails if a page lacks one.
- Every page now uses active voice. A new voice check in `style.test.mjs` flags a be-verb before a participle in prose and tables.
- The Zero overview links to the new `#why-ravintio` anchor.

## Why

The explainer gave Zero and Framework about 60% of its words, so new readers saw a coding agent rather than six tools with one purpose (backlog 0000023). Search results showed arbitrary page text (backlog 0000017). Passive sentences hid who acts (backlog 0000021).

## Deviations

- The design listed eight criteria. The requirements hold them as seven checkbox lines, mapped in the execution plan.
- The P3 quality review fixed the homepage meta description, which the design had left out of scope. This run's subtitle change made it contradict the page.
- Each unit ran as one TDD track per subagent on `opus`, and the improvement loop ran one cycle across the whole diff.

## Validation results

- `npm test`: 86 of 86 pass. `npx playwright test`: 33 pass and 1 existing skip.
- Typecheck, build, and `npm audit` pass with 0 vulnerabilities.
- Security: overall low, two informational findings.
- All seven criteria verified in the browser or by command.

## Skipped phases

None.

# Iteration Log - 0000024-explainer-six-tools

> **Audience:** The ship phase's build assessment (P4) and post-run technical review. This is NOT the PR changelog: the PR changelog (written at the start of ship) is the human-readable audit trail for PR reviewers.

**Skill:** [implement](../skills/ravintio-implement/SKILL.md)
**Date:** 2026-11-06

## Iteration Steps Completed

| Phase | Status | Gate Result | Notes |
|-------|--------|-------------|-------|
| P0 - Discovery | pass | Design confirmed: yes | 4 coaching questions, 9 backlog decisions, scope lock |
| P1 - Plan | pass | All artifacts produced: yes | 3 ADRs |
| P2 - Implement | pass | Implementation complete: yes | 1 deviation: the improvement loop ran one cycle across the whole diff |
| P3 - Validate and Accept | pass | CI clean and accepted: yes, by evidence in the PR | 0 cycles, 2 fix-now quality findings |
| P4 - Ship | pass | Archived and PR raised: yes | |

## Requirement Changes During Run

| Change | Phase Active | Classification | Action Taken |
|--------|-------------|----------------|-------------|
| None | none | none | none |

## Self-Correct Log

No TDD track needed a second attempt. The improvement review found four issues and the refactor step fixed all four in `5a61144`:

- The in-design tools read as promised with "will". The pages now state aims and design in the present tense.
- The voice check missed negated forms and other be-verbs. The pattern now covers them.
- The voice check skipped table cells. It now reads them.
- A dead exception for "as simple as the problem allows" remained. It is gone.

## Quirks

- The voice check matches straight apostrophes only, so a curly `isn’t` passes unflagged.
- The pre-commit advisory treats `src/web-app/component-docs/` as outside `docs/` and prints a warning on code commits that update it.

## Recommended Improvements

- Review the dropped ten "Why use RAVINTIO?" bullets, which included the human-agreed "as simple as the problem allows" lead from run 0000009.
- Review the new required `description` field, a breaking change to the manifest format.
- Review the new homepage subtitle and the "Why RAVINTIO?" text.
