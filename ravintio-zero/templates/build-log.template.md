---
title: "Build Log - {{feature-id}}"
summary: "Working record of the pipeline run, maintained by the orchestrator."
---
# Build Log - {{feature-id}}

> Created at discovery (P0). Appended by the orchestrator at each phase boundary. Survives session changes.

## Header

| Field | Value |
|-------|-------|
| Feature ID | `{{feature-id}}` |
| Pipeline start | `{{start-timestamp}}` |
| Tool | `{{tool-name}}` |
| Primary model | `{{primary-model-name}}` |
| Cheaper model | `{{cheaper-model-name}}` |
| Run speed | `{{fast | standard}}` |

---

## Phase Log

### P0: Discovery

| Field | Value |
|-------|-------|
| Start | `{{timestamp}}` |
| End | `{{timestamp, filled when the phase completes}}` |
| Wall clock | `{{whole minutes from Start to End}}` |
| Model tier | primary / cheaper |
| Skills loaded | ravintio-orchestrator |
| Agents spawned | `{{count}}` |
| MCP calls | `{{count}}` |
| Parallel task batches | `{{count}}` |
| Notes | `{{free text or "none"}}` |

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
