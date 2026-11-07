---
title: "Scope - site-quality-fixes"
summary: "Defines explicit boundaries of what is in scope and out of scope."
status: "active"
version: "0.1.0"
---
# Scope - site-quality-fixes

**Skill:** [plan](../skills/ravintio-plan/SKILL.md)
**Feature:** 0000027-site-quality-fixes
**Version:** 0.7.0

## In Scope

- Add `@axe-core/playwright` and scan every page in both themes, failing on serious or critical violations (REQ-001).
- Fix every serious or critical violation the first scan finds (REQ-001).
- Add `src/web-app/404.html` as a build input with `<base href="/">` (REQ-002).
- Wrap the homepage content in `<main id="content">` and check one `<main>` per page (REQ-003).
- Reduce card padding below 600 px so body text reaches at least 330 px at 390 px (REQ-004).
- Pin every action in `site-tests.yml` and `deploy.yml` by commit SHA, with a test (REQ-005).
- Point the header and footer code links to `https://github.com/RAVINTIO` with the label "RAVINTIO on GitHub" (REQ-006).
- Rewrite the `ravintio.yml` cell in `project-operations.md` with a named actor (REQ-007).

## Out of Scope

- Pins in `.github/workflows/ravintio.yml`, which `ravintio-zero/setup.sh` writes (story map gap).
- In-body links to the Zero repo in `six-tools.md` and `install-zero.md`, which name Zero on purpose.
- Axe rule exclusions, unless the human approves one.
- Backlog 0000014, Framework docs.

## Deferred

- Nothing deferred.
