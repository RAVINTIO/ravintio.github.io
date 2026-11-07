---
title: "Build Log - 0000027-site-quality-fixes"
summary: "Working record of the pipeline run, maintained by the orchestrator."
---
# Build Log - 0000027-site-quality-fixes

> Created at discovery (P0). Appended by the orchestrator at each phase boundary. Survives session changes.

## Header

| Field | Value |
|-------|-------|
| Feature ID | `0000027-site-quality-fixes` |
| Pipeline start | `2026-11-07T16:32:46Z` |
| Tool | `Claude Code` |
| Primary model | `claude-opus-5-5` |
| Cheaper model | `claude-sonnet-5-5` |
| Run speed | `standard` |

---

## Phase Log

### P0: Discovery

| Field | Value |
|-------|-------|
| Start | `2026-11-07T16:32:46Z` |
| End | `{{timestamp, filled when the phase completes}}` |
| Wall clock | `{{whole minutes from Start to End}}` |
| Model tier | primary / cheaper |
| Skills loaded | ravintio-orchestrator |
| Agents spawned | `0` |
| MCP calls | `0` |
| Parallel task batches | `0` |
| Notes | see notes below |


- Migration 0005 (initiative rename): skipped. Its `Applies when:` condition is false. No `plan/roadmap/*/roadmap.md` exists and `ravintio.yml` holds no `roadmap/**` pattern. It stays pending.
- Pack update check: resume detection compared pack `0.37.0` with the product version `0.6.0`. This is the false positive ruled in runs 0000009, 0000016, and 0000024. No `ravintio-zero/` file changed since `54db2ef`.
- Pre-flight: `main` matched `origin/main` with no open PRs. Cut `feat/pending`.
- Backlog pickup: the human accepted every recommendation. Pulled in 0000015, 0000018, 0000019, 0000020, 0000022, 0000025, and 0000026 (13 of 14 points). Left 0000014.
- Feature id reserved: 0000027-site-quality-fixes. Branch renamed to `feat/0000027-site-quality-fixes`.
- Commit hook blocked the `Claude-Session:` trailer. Commits carry no attribution line.
- P0 exchange (backlog pickup): Q: pull in, leave, or discard each backlog entry? / A: go with all recommendations.

---

<!-- Copy and fill in this block at each phase boundary. Headings use the form
     "### P<n>: {Phase Name}" with n from 1 to 4 and the phase names
     P1: Plan, P2: Implement, P3: Validate and Accept, P4: Ship.

### P<n>: {Phase Name}

| Field | Value |
|-------|-------|
| Start | `{{timestamp}}` |
| End | `{{timestamp, filled when the phase completes}}` |
| Wall clock | `{{whole minutes from Start to End}}` |
| Model tier | primary / cheaper |
| Skills loaded | `{{skill names}}` |
| Agents spawned | `{{count}}` |
| MCP calls | `{{count}}` |
| Parallel task batches | `{{count}}` |
| Notes | `{{free text or "none"}}` |

-->

<!-- Skipped phase. A phase with no block needs a line "Skipped: P<n> ({reason})".
     Ship runs ravintio-zero/scripts/build-log-check.mjs, which fails a missing
     block that has no such line.
-->

<!-- Progress markers. Each dispatched unit adds these lines under its phase
     block, per "Progress Markers and Interrupted Units" in
     ravintio-zero/standards/agent-dispatch-standards.md:

- In progress: {unit} ({ISO-8601 timestamp})
- Done: {unit} ({ISO-8601 timestamp})
- Resumed after interruption: {unit} rerun, {stash note}

-->

---

## Summary (filled at ship, P4)

| Metric | Value |
|--------|-------|
| Total phases completed | `{{count}}` |
| Total wall clock | `{{minutes from pipeline start to the P4 End}}` |
| Total agents spawned | `{{count}}` |
| Total MCP calls | `{{count}}` |
| Phases using parallelism | `{{count}}` |
| Primary tier agent calls | `{{count}}` |
| Cheaper tier agent calls | `{{count}}` |
| Self-corrections | `{{count}}` |
| Phases skipped | `{{list or "none"}}` |
