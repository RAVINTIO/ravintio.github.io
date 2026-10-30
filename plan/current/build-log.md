---
title: "Build Log - 0000009-bug-fixes"
summary: "Working record of the pipeline run, maintained by the orchestrator."
---
# Build Log - 0000009-bug-fixes

> Created at discovery (P0). Appended by the orchestrator at each phase boundary. Survives session changes.

## Header

| Field | Value |
|-------|-------|
| Feature ID | `0000009-bug-fixes` |
| Pipeline start | `2026-10-30T06:16:40Z` |
| Tool | `claude-code` |
| Primary model | `claude-opus-5-5` |
| Cheaper model | `claude-sonnet-5-5` |
| Run speed | `pending` |

---

## Phase Log

### P0: Discovery

| Field | Value |
|-------|-------|
| Start | `2026-10-30T06:16:40Z` |
| End | `pending` |
| Wall clock | `pending` |
| Model tier | primary |
| Skills loaded | ravintio-orchestrator, ravintio-file-backlog |
| Agents spawned | `0` |
| MCP calls | `0` |
| Parallel task batches | `0` |
| Notes | See the discovery notes below. |

#### Discovery notes

- Migration 0005 skipped: its `Applies when:` condition is false in this repo. It stays pending.
- Pack update check: resume detection compared pack `0.37.0` with the product version `0.4.0` in `docs/about.md`. The human ruled the pack version a dependency version that never affects the product version. No pack change arrived since `7a1cb5f` on `main`. Detector issue filed in the Zero repo as `plan/backlog/0000272-pack-version-vs-product-version/`, uncommitted.
- Pre-flight: PR #23 merged. `main` pulled to `54db2ef`. Branch `feat/0000009-bug-fixes` cut from `main`.
- Adoption mode assumed: Standard Iterative. Signal: `plan/_archive/` holds 4 runs beside `src/`.

#### Coaching log

P0 exchange (scope): Q: Which bug should this run fix, backlog 0000008, 0000007, or both? / A: Both, plus a number of bugs in the copy.
