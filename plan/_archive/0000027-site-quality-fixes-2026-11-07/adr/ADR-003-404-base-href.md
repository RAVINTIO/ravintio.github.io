---
title: "ADR 003: Serve the 404 page with a root base URL"
summary: "The 404 page sets base href to the domain root so it works at any depth."
status: "accepted"
version: "0.1.0"
---
# ADR-003 - Serve the 404 page with a root base URL

**Skill:** [plan](../skills/ravintio-plan/SKILL.md)
**Feature:** 0000027-site-quality-fixes
**Component:** web-app
**Date:** 2026-11-07

## Context

GitHub Pages serves `404.html` for any missing path, at any depth. The Vite config sets `base: './'`, so built pages reference assets by relative path. A relative path on `/docs/missing/page.html` resolves under `/docs/missing/` and fails. The site serves from the root of `ravintio.github.io`.

## Decision

Add `src/web-app/404.html` as a Vite build input. Put `<base href="/">` first in its `<head>`, so every relative asset and link resolves from the domain root.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Change `base` to `/` for the whole site | One rule for every page | Changes every page and breaks local `file://` previews | Wider change than one page needs |
| Inline all CSS and JS in the 404 page | No asset paths | Duplicates the stylesheet and theme script | Drifts from the site styles |

## Affected Components

| Component | Impact |
|-----------|--------|
| web-app | One new page and one new build input. |

## Consequences

**Positive:**
- The 404 page shares the site styles and works at every depth.

**Negative:**
- The page assumes the domain root. A move to a project path needs a new base.

**Risks:**
- R-007: the site moves off the domain root.

## Related ADRs

- 0000009 ADR-003 Group the nav manifest into sections with slug file names - related-to
