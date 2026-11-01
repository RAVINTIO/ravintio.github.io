---
title: "Backlog Entry: 0000014 - Document RAVINTIO Framework"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future discovery run."
status: "open"
---
# Backlog Entry: 0000014 - Document RAVINTIO Framework

**Source feature:** 0000016-site-regression-and-quality
**Source phase:** P0
**Deferral source:** deliberate scope decision
**Date filed:** 2026-10-31

---

## Problem

The docs site gives RAVINTIO Framework only an ecosystem overview entry. Full user docs cover RAVINTIO Zero alone. Framework has a local repo at `../framework`, so it has working code to document. This entry replaces backlog 0000006, which run 0000005 filed.

## Suggested Action

Add full user docs for RAVINTIO Framework beside the Zero docs, sourced from the Framework repo. Run the Playwright regression suite against the new pages.

## Why Deferred

The pending run pulled it in, then split it out. The three items came to about 16 points against a budget of 14. Framework is also under major rework, so docs written now would go stale. Pick this up once the rework settles.
