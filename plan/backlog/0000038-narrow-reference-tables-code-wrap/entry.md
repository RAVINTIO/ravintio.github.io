---
title: "Backlog Entry: 0000038 - Reference tables break code cells mid-word at 390 px"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future discovery run."
status: "open"
---
# Backlog Entry: 0000038 - Reference tables break code cells mid-word at 390 px

**Source feature:** 0000027-site-quality-fixes
**Source phase:** P3
**Deferral source:** discovered mid-flight
**Date filed:** 2026-11-07

---

## Problem

Area: layout. Pages: `/docs/pipeline.html` and the other pages with wide tables. At 390 px the Skill and Main output columns squeeze, and inline `code` breaks mid-word, for example "rav / int / io- / orch". The table also scrolls sideways inside its container. The page itself does not scroll sideways. The text column is now wide enough after the card padding change.

## Suggested Action

Give table `code` cells `white-space: nowrap` or `overflow-wrap: normal` below 600 px, and let the table scroll inside its wrapper. Add a Playwright check that no table cell wraps a code token.

## Why Deferred

The page does not overlap, clip, or scroll sideways, so it fails no fix-now rule. The table is readable by scrolling.
