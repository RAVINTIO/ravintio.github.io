---
title: "Backlog Entry: 0000008 - Collapse the section nav on mobile"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future discovery run."
status: "open"
---
# Backlog Entry: 0000008 - Collapse the section nav on mobile

**Source feature:** 0000005-ravintio-docs-rewrite
**Source phase:** P3
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-29

---

## Problem

Below 900 px wide, the full ten-link section nav in `src/web-app/scripts/build-docs.js` renders above the page content. At 360 px a reader scrolls past about one screen of links before the page text starts. The mobile menu shows only the three section links.

## Suggested Action

Collapse the section nav into a disclosure, such as a `<details>` element, below 900 px. Or move the ten page links into the mobile menu.

## Why Deferred

The run's mobile target is "no horizontal scroll at 360 px", which passes. The layout change needs its own design check.
