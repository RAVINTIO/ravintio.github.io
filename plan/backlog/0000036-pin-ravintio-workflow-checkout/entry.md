---
title: "Backlog Entry: 0000036 - Pin the checkout action in ravintio.yml"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future discovery run."
status: "open"
---
# Backlog Entry: 0000036 - Pin the checkout action in ravintio.yml

**Source feature:** 0000027-site-quality-fixes
**Source phase:** P3
**Deferral source:** discovered mid-flight
**Date filed:** 2026-11-07

---

## Problem

Run 0000027 pinned every action in `site-tests.yml` and `deploy.yml` to a commit SHA. `.github/workflows/ravintio.yml:18` still uses `actions/checkout@v4`, a movable tag. Line 56 of the same file already pins the same action to a SHA. The job at line 18 runs on pull requests and holds `contents: read`.

## Suggested Action

Pin the line 18 checkout in the pack's workflow source, which `ravintio-zero/setup.sh` copies to `.github/workflows/ravintio.yml`. Use the SHA from line 56, with the `# v4` comment beside it. File the change in the RAVINTIO Zero backlog, then refresh setup here. An edit to this repo's copy would revert on the next setup refresh.

## Why Deferred

Run 0000027 kept `ravintio.yml` out of scope because the pack writes it (0000027 ADR-004). The risk is low because the job has read-only permissions.
