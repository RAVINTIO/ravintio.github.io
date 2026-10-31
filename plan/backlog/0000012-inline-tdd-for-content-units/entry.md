---
title: "Backlog Entry: 0000012 - Inline TDD path for content units"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future discovery run."
status: "open"
---
# Backlog Entry: 0000012 - Inline TDD path for content units

**Source feature:** 0000009-bug-fixes
**Source phase:** P4
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-31

---

## Problem

`ravintio-implement` requires three subagents per requirement for the TDD loop. Runs 0000005 and 0000009 both ran content units inline and logged a departure each time. Source: `plan/retrospectives/0000009-bug-fixes-2026-10-31.md`.

## Suggested Action

In the `ravintio-zero` pack, define an inline TDD path for small units that apply agreed text or make single-file changes. Keep the RED-before-change rule and the build-log markers. This change belongs in the Zero repo. Copy the entry there with a local id.

## Why Deferred

It changes the pack, which is out of scope for this docs repo.
