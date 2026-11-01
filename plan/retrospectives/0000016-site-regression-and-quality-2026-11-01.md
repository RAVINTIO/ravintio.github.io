---
title: "Retrospective: 2026-11-01 - Site regression suite and quality review"
summary: "A blameless review of a finished run or initiative, and the changes it files."
status: "open"
---
# Retrospective: 2026-11-01 - Site regression suite and quality review

**Mode:** run
**Subject:** 0000016-site-regression-and-quality
**Date:** 2026-11-01

## Summary

Version 0.5.0 shipped six stories with 17 criteria. It adds a Playwright suite, CI tests, a P3 quality review, and the white flash fix. One P1 stop for an untestable criterion held the run. The rest of P1 to P4 ran without a human stop.

## What helped

- Each unit's test went RED before its change. U4's first-frame test failed 6 of 6 on the old templates before the fix (build log U4 line).
- A fresh-context review across the whole diff found that `vite preview` served the homepage for missing pages. The link check couldn't fail before the fix (build log `Improve:` line, commit `389a14f`).
- The first quality review found the untracked `.playwright-mcp/` folder that this run created. It also filed five site improvements (archived `site-quality-report.md`).
- Running a unit as one TDD track per subagent kept briefs short and let U1 and U6 run in parallel (build log P2 departures).

## What slowed the work

- REQ-002 AC-3 tested Mermaid diagrams, but no page holds one. P1 stopped for a rewording (build log `Blocked:` and `Resolved:` lines).
- The concurrency plan put U3 and U4 in one batch. Both rebuild `dist/` and use port 4173, so P2 ran them in sequence (build log P2 departure).
- Setup copies only `SKILL.md` into `.claude/skills/`, so the new skill couldn't find its report template until a fix (commit `c8fa2ef`).

## Keep

- One fresh-context review across the whole diff after the TDD tracks (build log `Improve:` line).
- The P3 quality review with the fix-now rule and the 2-point cap (archived `site-quality-report.md`).

## Change

- Name shared runtime resources, such as build output and ports, in the concurrency plan.
- Check that the content a criterion tests exists before the design gate.

## Actions

| Change | Owner | Lives in | Verified by | Filed as |
|--------|-------|----------|-------------|----------|
| Shared resources in the concurrency plan | pack maintainer | `ravintio-zero/templates/execution-plan.template.md`, `consistency-check.mjs` | A pack test on check 8 | Zero backlog 0000347, from this retrospective, uncommitted in the Zero repo |
| Content check before criteria | pack maintainer | Orchestrator P0 coaching reference | A pack test on the coaching reference | Zero backlog 0000348, from this retrospective, uncommitted in the Zero repo |
