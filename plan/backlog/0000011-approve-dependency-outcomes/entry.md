---
title: "Backlog Entry: 0000011 - Coach dependency approval for advisory fixes"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future discovery run."
status: "open"
---
# Backlog Entry: 0000011 - Coach dependency approval for advisory fixes

**Source feature:** 0000009-bug-fixes
**Source phase:** P2
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-31

---

## Problem

In run 0000009, the `Approved dependencies` field allowed only patch and minor updates "within current majors". That bound came from a P0 audit snapshot. The goal of the story was 0 advisories. When a new advisory needed a major bump, the bound and the goal conflicted, and P2 stopped. See `plan/postmortems/2026-10-31-advisory-after-discovery.md`.

## Suggested Action

In the `ravintio-zero` pack, add a discovery coaching question for advisory-fix stories. It asks whether a major bump of an existing dependency is pre-approved when it is the only fix. It records the answer in `Approved dependencies`. This change belongs in the Zero repo. Copy the entry there with a local id.

## Why Deferred

It changes the pack, which is out of scope for this docs repo.
