---
title: "Discovery - 0000009-bug-fixes"
summary: "Raw discovery-pass findings: what the orchestrator knew before coaching began."
---
# Discovery - 0000009-bug-fixes

## Header (all modes)

| Field | Value |
|-------|-------|
| Adoption mode detected | `standard-iterative` |
| Detection signal | `plan/_archive/` holds 4 runs beside `src/` |
| Git pre-flight | `feat/0000009-bug-fixes` cut from `main` at `54db2ef`. PR #23 merged, confirmed by the human. |
| Skills inbox | empty |

## Mode Findings

### Standard Iterative

- Current version (`docs/about.md`, `product.yml`): `0.4.0`. `versionPolicy: max-component-version`, `releaseSize: large`.
- Prior features (`plan/_archive/`): latest is `0000005-ravintio-docs-rewrite` (2026-10-29), the new ten-page RAVINTIO docs site.
- Constraining ADRs: 0000005 ADR-002 (`site-content` owns the Markdown, `web-app` reads it), ADR-003 (sectioned nav manifest), ADR-004 (brand guard), ADR-005 (reference pages match the pack).
- Components: `site-content` (pages, no data) and `web-app` (Vite build, reads `site-content`). No data-owning component.
- Repo instructions: `custom-002-push-and-raise-prs.md`. Push and raise PRs into `main`, never merge.
- Product id: `ravintio-docs`.

## Backlog

- `0000006-framework-docs`: open.
- `0000007-dependency-advisories`: open. The human named it for this run.
- `0000008-mobile-section-nav`: open. The human named it for this run.

## Resume findings

- Migration `0005-initiative-rename`: does not apply. Stays pending.
- Pack version check: false positive. Filed in the Zero repo as backlog `0000272`.
