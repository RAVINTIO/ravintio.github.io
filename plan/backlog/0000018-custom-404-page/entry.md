---
title: "Backlog Entry: 0000018 - Add a custom 404 page"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future discovery run."
status: "open"
---
# Backlog Entry: 0000018 - Add a custom 404 page

**Source feature:** 0000016-site-regression-and-quality
**Source phase:** P3
**Deferral source:** discovered mid-flight
**Date filed:** 2026-11-01

---

## Problem

Area: navigation and metadata. Page: any missing URL. The site has no `404.html`. GitHub Pages then shows its own 404 page, with no site nav or link back to the docs. Evidence: a request for `/404.html` on the preview returned 404 (finding N-002).

## Suggested Action

Add a `404.html` with the site header, a short message, and links to the homepage and the page list. Include it in the Vite build inputs and the page health suite.

## Why Deferred

The P3 site quality review sorted it as a backlog finding. It doesn't break an existing page, fail WCAG level A, or come from this run.

## Evidence 2026-11-06

The run 0000024 site quality review found this issue still present on the local preview.
