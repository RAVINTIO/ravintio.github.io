---
title: "Scope - ravintio-docs-rewrite"
summary: "Defines explicit boundaries of what is in scope and out of scope."
status: "active"
version: "0.1.0"
---
# Scope - ravintio-docs-rewrite

**Skill:** [plan](../skills/ravintio-plan/SKILL.md)
**Feature:** 0000005-ravintio-docs-rewrite
**Version:** 0.4.0

## In Scope

- Ten new Markdown pages in `src/site-content/pages/`, written from scratch (REQ-001 to REQ-003).
- The new `site-content` component, with `component.yml` and component docs (REQ-004).
- Deletion of `planifest-docs/`, `src/planifest-docs/`, the old generated HTML, the old logos, and the old favicons (REQ-004).
- A sectioned nav manifest, and `build-docs.js` changes to read the new folder and render sections (REQ-004).
- The supplied logo in the header with a "RAVINTIO" wordmark, a resized web copy, and a favicon set built from it (REQ-004).
- Earlier-brand removal from the homepage, site code, `web-app` manifests and component docs, repo docs, `plan/README.md`, and `plan/feature-structure.md` (REQ-004).
- Replacement of `refresh-planifest-framework-dir.ps1` with `refresh-ravintio-zero-dir.ps1` (REQ-004).
- Tests under `src/web-app/tests/` run by `node --test`: brand guard, capitals, nav order, links, style, and reference match.

## Out of Scope

- Full RAVINTIO Framework docs (backlog `0000006`).
- Site search.
- Renaming the GitHub repo. The human does this.
- A custom domain.
- Redirects from old URLs.
- README links in the `ravintio-zero` repo.
- Editing `plan/_archive/`, `plan/changelog/`, or the installed `ravintio-zero/` pack.

## Deferred

Nothing deferred.
