---
title: "Iteration Log - 0000016-site-regression-and-quality"
summary: "Execution log for the agent session."
status: "active"
version: "0.1.0"
---

# Changelog (0000016-site-regression-and-quality, 01 Nov 2026)

**Feature:** Site regression suite and quality review
**Version:** 0.5.0
**PR:** [#25](https://github.com/RAVINTIO/ravintio.github.io/pull/25)

## What changed

- A Playwright suite in `src/web-app/tests/e2e/` loads every page in Chromium. It checks status, console errors, links and anchors, and sideways scroll at 390 px. It also checks the theme toggle, the mobile page list, Mermaid diagrams, and the theme on first paint.
- `site-tests.yml` runs the content suite and the Playwright suite on each pull request into `main`. A failed run uploads the Playwright report.
- `.mcp.json` pins Playwright MCP at `0.0.83` for every session in the repo.
- A `site-quality-review` capability skill and repo instruction `custom-003` review the site in P3 of every run. Fix-now findings get fixed in the run, and the rest go to the backlog.
- An inline script sets the theme before first paint, so dark-theme readers no longer see a light frame.
- `vite.config.ts` sets `appType: 'mpa'`, so the dev and preview servers return 404 for a missing page.
- `.gitignore` covers `.playwright-mcp/`, `playwright-report/`, and `test-results/`.

## Why

The site had no browser tests, and CI ran no tests at all. Breakage reached readers before anyone saw it. Dark-theme readers saw a white flash on every page load (backlog 0000013).

## Deviations

- REQ-002 AC-3 now reports a named skip, because no page holds a Mermaid diagram. You approved the rewording in P1.
- Setup installs only `SKILL.md`, so the review skill reads its report template from `ravintio-overrides/`.
- P2 ran each unit as one TDD track per subagent, not three subagents. U4 and U3 ran in sequence because both use `dist/` and port 4173.
- The improvement review found that `vite preview` served the homepage for missing pages. `appType: 'mpa'` fixed it.

## Validation results

- `npm test` passes 53 of 53. `npm run test:e2e` passes 33, with 1 named skip. Typecheck, build, and `npm audit` pass.
- Browser checks in both themes at 390 px and 1280 px verified 15 criteria. REQ-003 AC-1 and AC-2 depend on this pull request's CI run.
- Security risk is low, with no critical, high, or medium finding.
- The first quality review fixed one item and filed backlog 0000017 to 0000021. The security review filed 0000022.

## Skipped phases

None

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
| P3 - Validate and Accept | pass | CI clean and accepted: yes (autonomous, evidence in the PR) | 1 cycle |
| P4 - Ship | pass | Archived and PR raised: yes | |

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
