---
title: "Scope - site-regression-and-quality"
summary: "Defines explicit boundaries of what is in scope and out of scope."
status: "active"
version: "0.1.0"
---
# Scope - site-regression-and-quality

**Skill:** [plan](../skills/ravintio-plan/SKILL.md)
**Feature:** 0000016-site-regression-and-quality
**Version:** 0.5.0

## In Scope

- A Playwright suite in `src/web-app` for page health: status, console errors, links and anchors, and 390 px scroll (REQ-001).
- Playwright tests for the theme toggle, the mobile page list, and Mermaid diagrams, with a named skip when no page holds one (REQ-002).
- `.github/workflows/site-tests.yml` on pull requests into `main`, running both suites and keeping the report on failure (REQ-003).
- `.mcp.json` with `@playwright/mcp` pinned at `0.0.83` (REQ-004).
- The `site-quality-review` capability skill, repo instruction `custom-003`, and the first review in this run's P3 (REQ-005).
- An inline theme script and a `color-scheme` meta tag in both page templates (REQ-006).
- `node --test` tests for the workflow, `.mcp.json`, the skill, and the instruction.

## Out of Scope

- Firefox and WebKit.
- Visual snapshot comparison.
- Changes to `deploy.yml` or `ravintio.yml`.
- Making `site-tests.yml` a required check. That's a GitHub branch protection setting for the human.
- Changes to the installed `ravintio-zero/` pack.
- New pages or changes to the nav order, except a page fix that the review marks fix-now.

## Deferred

- Full RAVINTIO Framework docs: backlog `0000014`. Blocked until the Framework rework settles. Nothing in this run waits on it.
- axe-core scans: backlog `0000015`. Until then, the review checks accessibility by hand from the accessibility tree.
