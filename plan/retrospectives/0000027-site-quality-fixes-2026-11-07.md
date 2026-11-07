---
title: "Retrospective: 2026-11-07 - Site quality fixes"
summary: "A blameless review of a finished run or initiative, and the changes it files."
status: "open"
---
# Retrospective: 2026-11-07 - Site quality fixes

**Mode:** run
**Subject:** 0000027-site-quality-fixes
**Date:** 2026-11-07

## Summary

The run closed seven backlog findings and added an axe-core scan that fails CI on serious violations. It shipped with no `Blocked:` stop, but one test failure went unseen until the improvement review.

## What helped

- Batch 1 of P2 ran three TDD tracks in parallel with disjoint files, and each landed on its first attempt (build log, `Done: U1` to `Done: U3`).
- The fresh-context improvement review found a failing phone-width test and a test that could not fail (commits `c53fe90`, `97522c8`).
- The first axe scan found two serious issues across every doc page that earlier manual reviews had passed (build log, `U7 first scan`).
- The P3 keyboard check found a WCAG 2.4.1 skip-link fault that predates the run (commit `7b8fb25`).

## What slowed the work

- A U7 suite check read only the last two lines of Playwright output, so it hid one failure. The build log recorded U7 as green (build log, `Self-correction` line under P2).
- One axe test covered three criteria but named only the first, so the P3 semantic check failed (commit `8926e2f`).
- The verification brief barred edits outside `style.css`, so US-005 AC-2 needed a second pass (commit `4e997d8`).
- A shell command that held the word "merge" in file text tripped `merge-guard`, and the edits moved to the Edit tool (build log, P3).

## Keep

- Run a fresh-context review across the whole diff after the TDD tracks (commits `c53fe90`, `97522c8`).
- Prove each failure path by a temporary break, then restore it (`verification-report.md`, US-001 AC-2 and US-005 AC-2).

## Change

- Read the passed, failed, and skipped counts from every test run (build log, P2 self-correction).
- Name every covered criterion in a test title (commit `8926e2f`).

## Actions

The `gate-write` hook blocks repo instruction writes after the archive, so both changes go to one backlog entry.


| Change | Owner | Lives in | Verified by | Filed as |
|--------|-------|----------|-------------|----------|
| Read whole test results | repo maintainer | `ravintio-overrides/instructions/custom-005-test-evidence.md`, and the local boot file that setup generates | Review of the next run's `Done:` lines against the test summaries | Backlog 0000039, from this retrospective |
| Name every criterion in test titles | repo maintainer | `ravintio-overrides/instructions/custom-005-test-evidence.md` | The P3 semantic check of the next run | Backlog 0000039, from this retrospective |
