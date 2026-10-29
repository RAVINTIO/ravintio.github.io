---
title: "ADR 002: site-content owns the page Markdown"
summary: "A new site-content component at src/site-content/ owns the pages, and web-app only reads them at build time."
status: "accepted"
version: "0.1.0"
---
# ADR-002 - site-content owns the page Markdown

**Skill:** [plan](../skills/ravintio-plan/SKILL.md)
**Feature:** 0000005-ravintio-docs-rewrite
**Component:** site-content
**Date:** 2026-10-29

## Context

Two manifests declared the same content component id, one at the repo root and one under `src/`. The root folder held the pages. The `src/` folder held the component docs. Feature 0000003 ADR-001 created that content component. The human confirmed one component, `site-content`, at `src/site-content/`. The archived ADR stays as written, because `plan/_archive/` is out of scope.

## Decision

Create `src/site-content/` with `component.yml`, `pages/`, and `docs/`. `site-content` owns every file in `pages/`. `web-app` reads `pages/*.md` at build time through `build-docs.js` and never writes there. Delete both old content folders.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Keep content at the repo root | Shorter path for editors | Breaks the monorepo standard of components under `src/` | Human chose `src/site-content/` |
| Merge content into `web-app` | One component | Mixes content ownership with build ownership | Content and build change for different reasons |

## Affected Components

| Component | Impact |
|-----------|--------|
| site-content | New. Owns the pages. |
| web-app | `build-docs.js` reads from `src/site-content/pages/`. Manifest `consumes` names `site-content`. |

## Consequences

**Positive:**
- One id, one folder, and one owner for the content.

**Negative:**
- Content editors work two levels deeper in the tree.

**Risks:**
- A future change writes pages from `web-app`. Mitigation: the `web-app` manifest lists that as an exception.

## Related ADRs

- ADR-003 - related-to

## Supersedes

- 0000003 ADR-001 (archived, left as written)

## Superseded By

- none
