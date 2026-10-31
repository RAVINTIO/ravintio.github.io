---
title: "Scope - bug-fixes"
summary: "Defines explicit boundaries of what is in scope and out of scope."
status: "active"
version: "0.1.0"
---
# Scope - bug-fixes

**Skill:** [plan](../skills/ravintio-plan/SKILL.md)
**Feature:** 0000009-bug-fixes
**Version:** 0.4.1

## In Scope

- New opening paragraph, "Why use RAVINTIO" list, and trimmed principles on `what-is-ravintio.md`, plus the `six-tools.md` pointer (REQ-001).
- The simplicity section on `zero-overview.md` and the P2 sentence on `pipeline.md` (REQ-002).
- The `zero-overview.md` reframe: "Why use Zero" first, "When Zero fits", and "Terms" last (REQ-003).
- Copy fixes on `first-run.md`, `install-zero.md`, `six-tools.md`, and the homepage subtitle (REQ-004).
- A collapsed page-list disclosure below 900 px in `build-docs.js`, `main.ts`, and `style.css` (REQ-005).
- `npm audit fix` within current majors in `src/web-app` (REQ-006).
- Content and built-HTML tests under `src/web-app/tests/` for each requirement.

## Out of Scope

- Full RAVINTIO Framework docs (backlog `0000006`).
- Changes to the installed `ravintio-zero/` pack.
- New pages or changes to the nav order.
- Major version bumps of any dependency.
- Reference pages (`skills.md`, `standards.md`, `templates.md`) and `project-operations.md`, which the site review left unchanged.

## Deferred

Nothing deferred.
