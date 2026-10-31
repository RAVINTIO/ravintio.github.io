---
title: "Backlog Entry: 0000010 - Refresh the dependency audit before implement"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future discovery run."
status: "open"
---
# Backlog Entry: 0000010 - Refresh the dependency audit before implement

**Source feature:** 0000009-bug-fixes
**Source phase:** P2
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-31

---

## Problem

Run 0000009 audited dependencies in P0 and planned the fix from that result. A new advisory (GHSA-238p-pmpm-9mq7 in `katex`) appeared before P2. Its fix needed a major bump outside the approved list, so P2 stopped. Nothing in P1 re-checks the audit. See `plan/postmortems/2026-10-31-advisory-after-discovery.md`.

## Suggested Action

In the `ravintio-zero` pack, have `ravintio-plan` re-run the dependency audit when a requirement targets advisories or dependency versions. Any fix outside the approved list then surfaces at the plan gate, not mid-implement. This change belongs in the Zero repo. Copy the entry there with a local id.

## Why Deferred

It changes the pack, which is out of scope for this docs repo.
