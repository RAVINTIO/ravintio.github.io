---
title: "Backlog Entry: 0000039 - Add a repo instruction for whole test results"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future discovery run."
status: "open"
---
# Backlog Entry: 0000039 - Add a repo instruction for whole test results

**Source feature:** 0000027-site-quality-fixes
**Source phase:** P4
**Deferral source:** retrospective `plan/retrospectives/0000027-site-quality-fixes-2026-11-07.md`
**Date filed:** 2026-11-07

---

## Problem

Run 0000027 recorded a Playwright run as green when one test had failed. The check read only the last two lines of output. One axe test also covered three criteria but named only the first, so the P3 semantic check failed.

## Suggested Action

Add `ravintio-overrides/instructions/custom-005-test-evidence.md` with this text, then refresh setup so the boot file picks it up:

- When you report a test run, read its passed, failed, and skipped counts. Never judge a run from its last lines alone.
- If one test covers several acceptance criteria, name each criterion in the test title, as in `req-001 AC-1 to AC-3`.

## Why Deferred

The retrospective runs after the archive. The `gate-write` hook blocks writes outside `plan/` once `plan/current/design.md` is gone, so the instruction can't land in this run.
