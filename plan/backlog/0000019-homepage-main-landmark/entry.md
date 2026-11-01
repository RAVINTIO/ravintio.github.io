---
title: "Backlog Entry: 0000019 - Add a main landmark to the homepage"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future discovery run."
status: "open"
---
# Backlog Entry: 0000019 - Add a main landmark to the homepage

**Source feature:** 0000016-site-regression-and-quality
**Source phase:** P3
**Deferral source:** discovered mid-flight
**Date filed:** 2026-11-01

---

## Problem

Area: accessibility. Page: the homepage (`src/web-app/index.html`). It has no `<main>` element, while every doc page has one. Screen reader users can't jump to the main content by landmark. The skip link to `#content` still works, so WCAG 2.4.1 passes. Evidence: `document.querySelector('main')` returned null on `/` (finding A-001).

## Suggested Action

Wrap the homepage content below the header in `<main id="content">`, and move the id from the hero header. Add a check to the page health suite that each page has one `<main>`.

## Why Deferred

The P3 site quality review sorted it as a backlog finding. The skip link meets WCAG level A, so it isn't fix-now. It is also a likely axe-core finding for backlog 0000015.
