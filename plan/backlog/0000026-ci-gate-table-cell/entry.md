---
title: "Backlog Entry: 0000026 - Name the actor in a project operations table cell"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future discovery run."
status: "open"
---
# Backlog Entry: 0000026 - Name the actor in a project operations table cell

**Source feature:** 0000024-explainer-six-tools
**Source phase:** P3
**Deferral source:** discovered mid-flight
**Date filed:** 2026-11-06

---

## Problem

Area: content. Page: `src/site-content/pages/project-operations.md`. A table cell reads "The CI gate only works once committed." It omits the actor and the be-verb, so it reads as passive, and the voice check in `style.test.mjs` cannot catch it. Evidence: the U3 TDD track in run 0000024 found it during the active-voice rewrite.

## Suggested Action

Rewrite the cell with a named actor, for example "The CI gate works only after you commit it."

## Why Deferred

The run 0000024 voice check does not flag it, and it lies outside the nine listed sentences. It doesn't break a page.
