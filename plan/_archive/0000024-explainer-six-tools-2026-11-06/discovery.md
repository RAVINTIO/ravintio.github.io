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
| Adoption mode detected | `standard-iterative` |
| Detection signal | `plan/_archive/` holds three prior runs and `src/` holds two components |
| Git pre-flight | `feat/pending`, one commit ahead of `origin/main` (`df9d48b`, backlog 0000023). Merge state of earlier PRs awaits human confirmation |
| Skills inbox | empty |

## Mode Findings

### Standard Iterative

- Current version (`docs/about.md`, `product.yml`): `0.5.0`. The most recent archive, 0000016, agrees.
- Version policy: `max-component-version`. Release size: `large` (14 points).
- Prior features (`plan/_archive/`):
  - 0000005-ravintio-docs-rewrite, 2026-10-29: rewrite of the docs site for RAVINTIO
  - 0000009-bug-fixes, 2026-10-31: copy reframe, mobile nav collapse, advisories
  - 0000016-site-regression-and-quality, 2026-11-01: Playwright suite, CI tests, quality review
- Constraining ADRs:
  - 0000005 ADR-001 stack and test runner, ADR-002 site-content owns pages, ADR-003 sectioned nav manifest, ADR-004 brand guard, ADR-005 reference matches pack
  - 0000016 ADR-001 Playwright browser tests, ADR-002 site tests workflow, ADR-003 quality review skill, ADR-004 inline theme script
- Component and data-ownership map: `site-content` owns the page Markdown and `docs.manifest.json`. `web-app` owns the build, templates, and homepage.
- Repo instructions (`ravintio-overrides/instructions/`): `custom-002-push-and-raise-prs.md`, `custom-003-site-quality-review.md`.

## Backlog

Next free id: `0000024`.

| Id | Title | Source | Estimate |
|----|-------|--------|----------|
| 0000014 | Document RAVINTIO Framework | 0000016 P0, deferred while Framework is reworked | L (4) |
| 0000015 | Add axe-core accessibility scans | 0000016 P0, human request | M (2) |
| 0000017 | Add meta descriptions to doc pages | 0000016 P3 | M (2) |
| 0000018 | Add a custom 404 page | 0000016 P3 | M (2) |
| 0000019 | Add a main landmark to the homepage | 0000016 P3 | S (1) |
| 0000020 | Widen the text column on phones | 0000016 P3 | S (1) |
| 0000021 | Rewrite passive sentences on three pages | 0000016 P3 | M (2) |
| 0000022 | Pin workflow actions by commit SHA | 0000016 P3 | M (2) |
| 0000023 | Rebalance the explainer to all six tools | human request, filed as the next release | M (2) |

## Past retrospectives

- 0000016 (2026-11-01). Keep the fresh-context review across the diff and the P3 quality review. Change: name shared runtime resources in the concurrency plan. Change: check that the content a criterion tests exists before the design gate. Both changes live in Zero backlog 0000347 and 0000348.
- 0000009 (2026-10-31) and 0000005 (2026-10-29): see `plan/retrospectives/`.
