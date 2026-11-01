---
title: "Backlog Entry: 0000020 - Widen the text column on phones"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future discovery run."
status: "open"
---
# Backlog Entry: 0000020 - Widen the text column on phones

**Source feature:** 0000016-site-regression-and-quality
**Source phase:** P3
**Deferral source:** discovered mid-flight
**Date filed:** 2026-11-01

---

## Problem

Area: layout. Page: all doc pages at 390 px. The page list card and the content card both add padding, so body text is 303 px wide in a 375 px viewport, starting 36 px from the edge. Lines wrap after five or six words. Evidence: `main p` measured at 303 px wide on `first-run.html` (finding L-001).

## Suggested Action

Reduce the content card's side padding below 600 px, or drop the card border and background on phones, so the text column reaches about 340 px.

## Why Deferred

The P3 site quality review sorted it as a backlog finding. Nothing overlaps or clips, and the page doesn't scroll sideways, so it isn't fix-now.
