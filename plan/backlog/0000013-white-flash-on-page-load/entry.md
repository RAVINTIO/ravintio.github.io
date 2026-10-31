---
title: "Backlog Entry: 0000013 - White flash on page load"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future discovery run."
status: "open"
---
# Backlog Entry: 0000013 - White flash on page load

**Source feature:** none (human request)
**Source phase:** none (human request)
**Deferral source:** human request
**Date filed:** 2026-10-31

---

## Problem

The screen flashes white when a page loads. The human found it on the local preview of 0.4.1.

Likely cause, not yet confirmed in a browser: the theme reaches the page too late.

- `src/web-app/src/main.ts` sets `data-theme` on `<html>` from `localStorage` or `prefers-color-scheme`.
- That code runs in a deferred module script (`<script type="module">` in the page head), so it runs after the browser has parsed the page.
- `src/web-app/src/style.css` defaults to the light palette and switches only on `[data-theme="dark"]`.
- A reader on the dark theme can see one light frame before the script applies the dark theme.

## Suggested Action

Set the theme before first paint. One option is a small inline script at the top of `<head>`, in `build-docs.js` and `index.html`, that sets `data-theme` from `localStorage` or `prefers-color-scheme`. A `color-scheme` meta tag or a `prefers-color-scheme` media query for the default palette would also cover readers with no saved choice. Confirm the cause in a browser first, in both themes, on a doc page and on the homepage.

## Why Deferred

The human asked to file it. Run 0000009 has shipped, and its PR #24 is awaiting review.
