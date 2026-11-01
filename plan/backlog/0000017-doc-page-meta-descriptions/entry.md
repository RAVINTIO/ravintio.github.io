---
title: "Backlog Entry: 0000017 - Add meta descriptions to doc pages"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future discovery run."
status: "open"
---
# Backlog Entry: 0000017 - Add meta descriptions to doc pages

**Source feature:** 0000016-site-regression-and-quality
**Source phase:** P3
**Deferral source:** discovered mid-flight
**Date filed:** 2026-11-01

---

## Problem

Area: navigation and metadata. Page: all ten doc pages. None of them has a `<meta name="description">`. Only the homepage has one. Search results and link previews then show arbitrary page text. Evidence: the review read `document.querySelector('meta[name=description]')` on each page in `plan/_archive/0000016-site-regression-and-quality-2026-11-01/site-quality-report.md` (finding N-001).

## Suggested Action

Give each page a description. One option is a `description` field per page in `docs.manifest.json`, which the `build-docs.js` template writes into `<head>`. Add a regression test that every page has a unique description.

## Why Deferred

The P3 site quality review sorted it as a backlog finding. It doesn't break the page, fail WCAG level A, or come from this run.
