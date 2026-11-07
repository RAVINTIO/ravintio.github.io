---
title: "Backlog Entry: 0000025 - Point the header code link beyond Zero"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future discovery run."
status: "open"
---
# Backlog Entry: 0000025 - Point the header code link beyond Zero

**Source feature:** 0000024-explainer-six-tools
**Source phase:** P1
**Deferral source:** deliberate scope decision
**Date filed:** 2026-11-06

---

## Problem

Area: navigation. Pages: the homepage and every doc page. The header code icon links to the RAVINTIO Zero repository only, with the label "RAVINTIO Zero on GitHub". The site now presents six tools with one shared purpose, so the header still points readers to one tool. The run 0000024 story map recorded this step as a gap and `scope.md` put it out of scope.

## Suggested Action

Point the link to the RAVINTIO GitHub organisation, or drop it in favour of links on each tool entry. Update the `aria-label` and `title` to match.

## Why Deferred

The run 0000024 design limited the homepage change to the subtitle.
