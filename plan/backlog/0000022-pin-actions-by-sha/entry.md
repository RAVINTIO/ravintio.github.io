---
title: "Backlog Entry: 0000022 - Pin workflow actions by commit SHA"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future discovery run."
status: "open"
---
# Backlog Entry: 0000022 - Pin workflow actions by commit SHA

**Source feature:** 0000016-site-regression-and-quality
**Source phase:** P3
**Deferral source:** discovered mid-flight
**Date filed:** 2026-11-01

---

## Problem

`.github/workflows/site-tests.yml` and `deploy.yml` reference `actions/checkout@v5`, `actions/setup-node@v5`, `actions/upload-artifact@v4`, and the Pages actions by tag. A moved tag would run different code in CI. Security report finding S-001, rated low.

## Suggested Action

Pin each action by full commit SHA, with the tag in a comment. Add a check in `site-tests-workflow.test.mjs` that every `uses:` line holds a 40-character SHA.

## Why Deferred

It affects `deploy.yml`, which this run kept out of scope. The risk is low because all the actions are GitHub-owned.
