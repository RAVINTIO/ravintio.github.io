---
title: "Backlog Entry: 0000015 - Add axe-core accessibility scans"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future discovery run."
status: "open"
---
# Backlog Entry: 0000015 - Add axe-core accessibility scans

**Source feature:** pending
**Source phase:** P0
**Deferral source:** human request
**Date filed:** 2026-10-31

---

## Problem

The pending run adds a `site-quality-review` capability skill. Its accessibility check reads the accessibility tree through Playwright MCP and judges WCAG 2.2 AA by hand. A manual review misses rules that an automated engine checks on every element.

## Suggested Action

Add `@axe-core/playwright` as a dev dependency. Run an axe scan on each manifest page in the Playwright regression suite, in both themes. Decide whether a serious or critical violation fails the suite, and feed the remaining violations into the quality review's triage.

## Why Deferred

The pending run chose a review with no new dependency. The human asked to file axe-core scans for a later run.
