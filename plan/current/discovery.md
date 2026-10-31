---
title: "Discovery - pending"
summary: "Raw discovery-pass findings: what the orchestrator knew before coaching began."
---
# Discovery - pending

> Created at the start of discovery (P0), before the first coaching question, in every adoption mode.
> Raw findings only. Decisions belong in `design.md`, the Q&A audit trail in `build-log.md`.
> Unreadable signal: say so, and coaching proceeds.

## Header (all modes)

| Field | Value |
|-------|-------|
| Adoption mode detected | `standard-iterative` (assumed, the only signal) |
| Detection signal | `plan/_archive/` holds feature dirs, and `docs/about.md` exists |
| Git pre-flight | `feat/pending` cut from `main` at `ec07aad` after PR 24 merged. The human confirmed. |
| Skills inbox | empty (`README.md` only) |

## Mode Findings

### Standard Iterative

- Current version (`docs/about.md`): `0.4.1`. `product.yml` agrees, with `versionPolicy: max-component-version`.
- Product id: `ravintio-docs`.
- Release size: `large`, a budget of 14 points.
- Repo instructions: `ravintio-overrides/instructions/custom-002-push-and-raise-prs.md`.
- Prior features (`plan/_archive/`):
  - `0000001-doc-nav` (2026-05-16): manifest-driven nav.
  - `0000002-doc-structure` (2026-05-18): docs structure, now superseded.
  - `0000003-p9-phase-docs` (2026-05-18): phase docs, now superseded.
  - `0000005-ravintio-docs-rewrite` (2026-10-29): rewrite for RAVINTIO, Zero-only full docs.
  - `0000009-bug-fixes` (2026-10-31): copy reframe, mobile nav, advisory fixes.
  - `website`, `website-nav-sitemap`, `website-refinements`: pre-id runs.
- Constraining ADRs (active, from `docs/decisions-index.md`):
  - website ADR-001 to ADR-003: Vite static site, build-time Markdown, GitHub Pages deploy.
  - 0000005 ADR-001: tests use `node --test` with no new dependency. A Playwright suite conflicts with this and needs a superseding ADR.
  - 0000005 ADR-002: `site-content` owns the page Markdown.
  - 0000005 ADR-003: sectioned nav manifest with slug file names.
  - 0000005 ADR-004: brand guard test. ADR-005: reference pages checked against the installed pack.
  - 0000009 ADR-001: stay within current majors, except by human approval. ADR-002: native disclosure for the mobile page list.
- Component and data-ownership map: `site-content` owns `src/site-content/pages/*.md`. `web-app` owns the build, the template, `docs.manifest.json`, and the tests.

## Candidate work

| Source | Item | Notes |
|--------|------|-------|
| Backlog 0000006 | Full user docs for RAVINTIO Framework | Source is `../framework`, last commit `f4728ff` on 2026-10-31. |
| Backlog 0000013 | White flash on page load | Likely cause: theme set in a deferred module script after first paint. Not yet confirmed in a browser. |
| Human request | Playwright MCP, a Playwright regression suite, and a site quality review each run | Playwright MCP is already connected at user scope (`npx @playwright/mcp@latest`). The repo has no `.mcp.json`. |

## Past retrospectives

- `plan/retrospectives/0000009-bug-fixes-2026-10-31.md`. Keep: an agreed-copy file for confirmed text, and one fresh-context review across the whole diff. Change: an inline TDD path and an audit refresh. Both moved to Zero as backlog 0000330 and 0000328.
- No other records exist.

## Hooks

- `gate-write` is registered in `.claude/settings.json`.
- `plan/.orchestrator-strict` exists.
