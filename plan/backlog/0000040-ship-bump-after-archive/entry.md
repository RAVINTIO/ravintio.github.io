---
title: "Backlog Entry: 0000040 - Let ship bump product.yml after the archive"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future discovery run."
status: "open"
---
# Backlog Entry: 0000040 - Let ship bump product.yml after the archive

**Source feature:** 0000027-site-quality-fixes
**Source phase:** P4
**Deferral source:** discovered mid-flight
**Date filed:** 2026-11-07

---

## Problem

Ship Step 4 archives `plan/current/`, which removes `design.md`. Ship Step 6 then writes `product.yml` and the retrospective writes `ravintio-overrides/instructions/`. The `gate-write` hook gates both paths and blocks the Write and Edit tools once `design.md` is gone. In run 0000027 the human approved a shell edit of `product.yml` instead. The repo instruction from the retrospective went to backlog 0000039.

## Suggested Action

File this in the RAVINTIO Zero backlog. Two fixes would work:

- Run the version bump before the archive.
- Let `gate-write` permit `product.yml` and `ravintio-overrides/instructions/` while `plan/.orchestrator-active` exists.

## Why Deferred

The fix belongs to the pack, which this repo installs but does not change.
