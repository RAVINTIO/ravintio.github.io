---
title: "Scope - explainer-six-tools"
summary: "Defines explicit boundaries of what is in scope and out of scope."
status: "active"
version: "0.1.0"
---
# Scope - explainer-six-tools

**Skill:** [plan](../skills/ravintio-plan/SKILL.md)
**Feature:** 0000024-explainer-six-tools
**Version:** 0.6.0

## In Scope

- Rewrite `src/site-content/pages/what-is-ravintio.md` around the shared purpose, with one entry per tool of about equal length (REQ-001).
- Change the homepage subtitle in `src/web-app/index.html` to name the shared purpose (REQ-001).
- Move links to the `#why-use-ravintio` anchor to `#why-ravintio` (REQ-001).
- Add a `description` to each page in `src/web-app/docs.manifest.json` and write it into each page `<head>` (REQ-002).
- Rewrite passive sentences on every page that the new check flags (REQ-003).
- Add a passive-voice check with an allowlist to `src/web-app/tests/style.test.mjs` (REQ-003).
- Update the tests that pin the old explainer and subtitle text.

## Out of Scope

- Rebalancing the content of `six-tools.md`. It changes only for active voice.
- The header code link, which points to the Zero repository only (story map gap).
- Moving the ten "Why use RAVINTIO?" bullets into the Zero overview.
- The homepage meta description.
- Backlog 0000014, 0000015, 0000018, 0000019, 0000020, and 0000022.

## Deferred

- Nothing deferred.
