---
title: "Iteration Log - 0000016-site-regression-and-quality"
summary: "Execution log for the agent session."
status: "active"
version: "0.1.0"
---
# Iteration Log - 0000016-site-regression-and-quality

> **Audience:** The ship phase's build assessment (P4) and post-run technical review. This is NOT the PR changelog: the PR changelog (written at the start of ship) is the human-readable audit trail for PR reviewers.

**Skill:** [implement](../skills/ravintio-implement/SKILL.md)
**Date:** 2026-11-01

## Iteration Steps Completed

| Phase | Status | Gate Result | Notes |
|-------|--------|-------------|-------|
| P0 - Discovery | pass | Design confirmed: yes | 13 coaching exchanges and the scope lock |
| P1 - Plan | pass | All artifacts produced: yes | 4 ADRs |
| P2 - Implement | pass | Implementation complete: yes | 1 deviation: the skill reads its report template from the source path |
| P3 - Validate and Accept | pending | CI clean and accepted: pending | |
| P4 - Ship | pending | Archived and PR raised: pending | |

## Requirement Changes During Run

| Change | Phase Active | Classification | Action Taken |
|--------|-------------|----------------|-------------|
| US-002 AC-3 now checks diagrams when a page holds one and reports a named skip when none does | P1 | cosmetic | Reworded in `design.md` and REQ-002. Nothing re-ran. |

## Self-Correct Log

- U1: `__dirname` is undefined in the ESM package. The page list now reads the manifest from the config directory.
- U3: Playwright's list reporter hides `test.skip` reasons. AC-3 now prints its reason before it skips.
- U6: setup copies only `SKILL.md` into `.claude/skills/`. The skill now reads `report.template.md` from `ravintio-overrides/capability-skills/site-quality-review/`.
- Review: `vite preview` served the homepage with status 200 for a missing page. `appType: 'mpa'` in `vite.config.ts` makes the dev and preview servers return 404, as GitHub Pages does. REQ-006 AC-1 and AC-2 also got tighter checks.

## Quirks

- The Playwright suite tests an existing build, so `npm run build` runs first (`web-app` Q-006).
- The theme logic lives in the inline script and in `main.ts` (`web-app` Q-007).
- No page holds a Mermaid diagram, so REQ-002 AC-3 reports a skip until a page adds one.
- `architecture-overview.md` listed `mermaid` 11. It now lists 12, which `package.json` has held since 0000009.

## Recommended Improvements

- Add `site-tests.yml` as a required check in the branch protection settings, so a failed suite blocks a merge.
- The first-frame test blocks module scripts and reads the theme after load. It proves that the inline script sets the theme without `main.ts`. It doesn't measure paint order itself.
