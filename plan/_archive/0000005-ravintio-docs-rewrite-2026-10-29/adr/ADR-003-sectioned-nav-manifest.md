---
title: "ADR 003: Group the nav manifest into sections with slug file names"
summary: "docs.manifest.json moves from a flat page list to labelled sections, and pages take slug file names without number prefixes."
status: "accepted"
version: "0.1.0"
---
# ADR-003 - Group the nav manifest into sections with slug file names

**Skill:** [plan](../skills/ravintio-plan/SKILL.md)
**Feature:** 0000005-ravintio-docs-rewrite
**Component:** web-app
**Date:** 2026-10-29

## Context

Feature 0000001 ADR-001 made `docs.manifest.json` the single source of page order, as a flat `pages` array. The confirmed structure has three labelled sections. The old file names carried number prefixes such as `01-`, and feature 0000002 ADR-003 placed a page out of numeric order. Page file names become public URLs.

## Decision

Change the manifest to `{ "sections": [ { "title": "RAVINTIO", "pages": [ { "file": "what-is-ravintio.html", "title": "What is RAVINTIO" } ] } ] }`. `build-docs.js` flattens sections in order for prev and next links and renders each section as a labelled group in the nav. Name pages by slug: `what-is-ravintio`, `six-tools`, `zero-overview`, `install-zero`, `first-run`, `pipeline`, `project-operations`, `skills`, `standards`, and `templates`.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Keep the flat list and add a `section` field per page | Smaller change to the build | Section order depends on page order, so sections can split | Grouping in the data is clearer |
| Keep number prefixes | Files sort in order on disk | Numbers drift from nav order, as they did before | The manifest already sets order |

## Affected Components

| Component | Impact |
|-----------|--------|
| web-app | Manifest format, nav rendering, sitemap, and the mobile menu change |

## Consequences

**Positive:**
- Nav sections come from one place, and URLs stay stable when pages move.

**Negative:**
- Any tool that reads the old flat format breaks. Only `build-docs.js` reads it today.

**Risks:**
- The mobile menu reads `sitemap-data.json` and could lose sections. Mitigation: the sitemap data keeps the section title per page.

## Related ADRs

- ADR-002 - related-to

## Supersedes

- 0000001 ADR-001 manifest format (extended; the manifest stays the source of truth) and 0000002 ADR-003 page placement (archived, left as written)

## Superseded By

- none
