---
title: "Backlog Entry: 0000007 - Clear npm audit advisories"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future discovery run."
status: "open"
---
# Backlog Entry: 0000007 - Clear npm audit advisories

**Source feature:** 0000005-ravintio-docs-rewrite
**Source phase:** P3
**Deferral source:** tech debt
**Date filed:** 2026-10-29

---

## Problem

`npm audit` in `src/web-app` reports 16 advisories (12 high, 2 moderate, 2 low). Every one sits in a dev dependency. `vite` and `mermaid` are the direct ones. `mermaid` and its `dompurify` dependency ship in the browser bundle, but they only render diagrams that the repo's own pages hold. Production `npm audit --omit=dev` reports none.

## Suggested Action

Run `npm audit fix`, upgrade `vite` and `mermaid` to patched releases, and rerun `npm run build` and `npm test`.

## Why Deferred

Upgrading dependencies was outside the approved dependency list for feature 0000005. The advisories predate the run.
