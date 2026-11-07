---
title: "Backlog Entry: 0000037 - Skip link on the 404 page leaves the page without JavaScript"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future discovery run."
status: "open"
---
# Backlog Entry: 0000037 - Skip link on the 404 page leaves the page without JavaScript

**Source feature:** 0000027-site-quality-fixes
**Source phase:** P3
**Deferral source:** discovered mid-flight
**Date filed:** 2026-11-07

---

## Problem

Area: navigation and accessibility. Page: `/404.html` and any missing path. The 404 page sets `<base href="/">`, so the skip link `href="#content"` resolves to `/#content`. With JavaScript on, `main.ts` intercepts the click and the visitor stays on the page. A keyboard check with Tab and Enter on the preview confirmed this. With JavaScript off, Enter loads the homepage.

## Suggested Action

Replace the skip link on the 404 page with one that works under `<base>`, for example by resolving the target in a small inline script, or by dropping `<base>` and writing root-relative asset paths in `404.html`.

## Why Deferred

The effect needs a visitor who has disabled JavaScript and reaches a missing page. The page stays usable, and the home link lands somewhere valid.
