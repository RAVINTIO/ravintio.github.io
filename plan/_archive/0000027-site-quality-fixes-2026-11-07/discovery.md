---
title: "Discovery - 0000027-site-quality-fixes"
summary: "Raw discovery-pass findings: what the orchestrator knew before coaching began."
---
# Discovery - 0000027-site-quality-fixes

> Created at the start of discovery (P0), before the first coaching question, in every adoption mode.
> Raw findings only. Decisions belong in `design.md`, the Q&A audit trail in `build-log.md`.
> Unreadable signal: say so, and coaching proceeds.

## Header (all modes)

| Field | Value |
|-------|-------|
| Adoption mode detected | `standard-iterative` |
| Detection signal | `plan/_archive/` holds 7 prior runs beside source in `src/` |
| Git pre-flight | `feat/0000027-site-quality-fixes` cut from `main`, which matched `origin/main` with no open PRs |
| Skills inbox | 3 repo instructions (`custom-002`, `custom-003`, `custom-004`). No `SKILL.md`. |

## Mode Findings

### Standard Iterative

- Current version (`docs/about.md`, `product.yml`): `0.6.0`, `versionPolicy: max-component-version`
- Release budget: `releaseSize: large`, 14 points
- Prior features (`plan/_archive/`):
  - 0000005 (2026-10-29): rewrite the docs site for RAVINTIO
  - 0000009 (2026-10-31): reframe copy, collapse mobile nav, clear advisories
  - 0000016 (2026-11-01): Playwright suite, CI tests, and quality review
  - 0000024 (2026-11-06): rebalance the explainer to all six tools
- Constraining ADRs:
  - Keep the declared Vite stack and test with `node --test` beside Playwright
  - The sectioned docs manifest drives nav order and build inputs (ADR-003, 0000009)
  - `site-content` owns the page Markdown. `web-app` owns the build and shell.
  - Run site tests in a separate pull request workflow
  - Run the quality review as a capability skill from a repo instruction
- Component and data-ownership map: `site-content` owns `src/site-content/pages/`. `web-app` owns `src/web-app/` (`index.html`, `scripts/build-docs.js`, `src/style.css`, tests).
- Repo instructions: push and raise PRs but never merge, run `site-quality-review` in P3, and sweep the old framing in content rewrites.

## Backlog pickup

| Entry | Decision | Size | Points |
|-------|----------|------|--------|
| 0000014 Document RAVINTIO Framework | leave (Framework still under rework) | L+ | n/a |
| 0000015 Add axe-core accessibility scans | pull-in | L | 4 |
| 0000018 Add a custom 404 page | pull-in | M | 2 |
| 0000019 Add a main landmark to the homepage | pull-in | S | 1 |
| 0000020 Widen the text column on phones | pull-in | S | 1 |
| 0000022 Pin workflow actions by commit SHA | pull-in | M | 2 |
| 0000025 Point the header code link beyond Zero | pull-in | M | 2 |
| 0000026 Name the actor in a project operations table cell | pull-in | S | 1 |

Total: 13 of 14 points. The human accepted every recommendation.

## Framing sweep (0000025)

Places that frame the site as RAVINTIO Zero only through the GitHub link:

- `src/web-app/index.html:53`: header code link, `href`, `aria-label`, and `title`
- `src/web-app/index.html:118`: footer **GitHub** link
- `src/web-app/scripts/build-docs.js:14`: `REPO_URL`, used by the doc page header (line 118) and footer (line 136)
- `src/site-content/pages/six-tools.md` and `install-zero.md`: in-body links to the Zero repo, which name Zero on purpose

## Past retrospectives

- 0000024: keep the framing sweep in P0 and the whole-paragraph reread after an improvement refactor. Both live in `custom-004`.
- 0000016: list shared resources in the concurrency plan (Zero backlog 0000347). Check content before criteria (Zero backlog 0000348).
- 0000009: no open changes.
