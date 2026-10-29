---
title: "Discovery - 0000005-ravintio-docs-rewrite"
summary: "Raw discovery-pass findings: what the orchestrator knew before coaching began."
---
# Discovery - 0000005-ravintio-docs-rewrite

> Created at the start of discovery (P0), before the first coaching question, in every adoption mode.
> Raw findings only. Decisions belong in `design.md`, the Q&A audit trail in `build-log.md`.
> Unreadable signal: say so, and coaching proceeds.

## Header (all modes)

| Field | Value |
|-------|-------|
| Adoption mode detected | `standard-iterative` (assumed) |
| Detection signal | `plan/_archive/` holds 3 runs beside source in `src/` |
| Git pre-flight | Branch `feat/0000005-ravintio-docs-rewrite` cut from `main` at `226afa4`. The human confirmed the branch cut. |
| Skills inbox | empty |

## Brief (human request, 2026-10-28)

- Rewrite all content for the docs website.
- Change the GitHub Pages address. The org is now `RAVINTIO`, and the repo becomes `ravintio-docs`.
- Pulled-in backlog entry `0000004-ravintio-rebrand`: rename brand, folders, and file names from Planifest to RAVINTIO. Lessons carried from RAVINTIO Zero feature 0000160:
  - Protect history ids, sibling repo names, and split literals from the bulk replace.
  - Leave `plan/_archive/`, `plan/changelog/`, and applied migrations as written.
  - Add a brand guard test with a path and line allowlist.
  - Run Bash suites under Bash 5 or in CI.
- Follow-up outside this repo: update README links in `RAVINTIO/ravintio-zero` that name `planifest-docs`.

## Mode Findings

### Standard Iterative

- Current version: `0.3.0` (`src/web-app/component.yml`). `docs/about.md` is missing, so no cross-check is possible. `product.yml` holds only `id`.
- Prior features (`plan/_archive/`):
  - `0000001-doc-nav` (2026-05-16): manifest-driven page order and nav injection.
  - `0000002-doc-structure` (2026-05-18): three-file docs structure and two-tier depth.
  - `0000003-p9-phase-docs` (2026-05-18): `planifest-docs` component manifest and anchor clean-up.
  - Older undated folders: `website`, `website-nav-sitemap`, `website-refinements`.
- Constraining ADRs (unless superseded):
  - 0000001 ADR-001 manifest as page-order source of truth.
  - 0000001 ADR-002 nav injection through a template placeholder.
  - 0000002 ADR-001 three-file docs structure.
  - 0000002 ADR-002 two-tier depth model.
  - 0000002 ADR-003 project-operations website page.
  - 0000003 ADR-001 `planifest-docs` component manifest.
  - 0000003 ADR-002 remove broken anchors rather than add sections.
- Component map:
  - `web-app` (`src/web-app/`, `0.3.0`): Vite site, built to `dist/`, deployed by `.github/workflows/deploy.yml`.
  - `planifest-docs` (`planifest-docs/`, `0.2.0`): 11 content pages, `01-overview.md` to `11-project-operations.md`.
  - `planifest-docs` (`src/planifest-docs/`, `0.1.0`): a second manifest with the same id. Ownership conflict to settle in coaching.
- Repo instructions (`ravintio-overrides/instructions/`): `custom-001-local-git-only.md`.
- Pages address: no `CNAME` and no hard-coded `github.io` URL in source. GitHub derives the address from owner and repo, giving `ravintio.github.io/ravintio-docs` after the rename. `vite.config.ts` uses `base: './'`.
- Release size: `releaseSize` absent, so the `medium` budget (8 points) applies.

## Past retrospectives

none
