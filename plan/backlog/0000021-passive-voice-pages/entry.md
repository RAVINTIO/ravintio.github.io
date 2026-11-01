---
title: "Backlog Entry: 0000021 - Rewrite passive sentences on three pages"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future discovery run."
status: "open"
---
# Backlog Entry: 0000021 - Rewrite passive sentences on three pages

**Source feature:** 0000016-site-regression-and-quality
**Source phase:** P3
**Deferral source:** discovered mid-flight
**Date filed:** 2026-11-01

---

## Problem

Area: content. Pages: `six-tools.md`, `project-operations.md`, and `skills.md`. These sentences break the repo's active-voice rule:
- `six-tools.md` lines 21, 24, 83, and 85: "is designed to".
- `project-operations.md` line 3: "how commit messages are checked".
- `project-operations.md` line 11: "if code is staged without documentation".
- `project-operations.md` line 133: "The pack is shared with the team".
- `skills.md` line 26: "after the design is confirmed".
Evidence: a scan of `src/site-content/pages/` for "is" or "are" plus a participle (finding C-001). The "are merged" and "you are satisfied" hits in `first-run.md` are adjectives, not passive voice.

## Suggested Action

Rewrite each sentence with a named actor, for example "Accept checks a change from..." and "the hook checks commit messages". Consider a passive-voice check in `style.test.mjs`.

## Why Deferred

The P3 site quality review sorted it as a backlog finding. `style.test.mjs` doesn't check voice, so the pages pass their tests. It doesn't break a page or come from this run.
