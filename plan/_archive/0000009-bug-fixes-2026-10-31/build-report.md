# Build Report - 0000009-bug-fixes

**Run speed:** standard

## Phases

| Phase | Agents | Model tier | Wall clock (min) | Parallel batches |
|-------|--------|------------|------------------|------------------|
| P0 Discovery | 0 | primary | 1857 | 0 |
| P1 Plan | 0 | primary | 2 | 0 |
| P2 Implement | 1 (sonnet reviewer) | primary, cheaper for the reviewer | 96 | 3, run in sequence inline |
| P3 Validate and Accept | 0 | primary | 3 | 0 |
| P4 Ship | 0 | primary | 0 | 0 |

P0 and P2 wall clock include time spent waiting on the human. The P0 figure spans two sessions.

## Parallelism

- P1 wrote six requirements, two ADRs, and the plan set inline. The plan skill marks independent requirement files as parallel work.
- P2 planned three batches and ran every unit inline in sequence. The build log records the departure.
- P3 ran its checks in sequence.

## Self-corrections

None. Two 0.4.0 tests failed after U1. The build log records both as departures that follow the confirmed design, not as rework.

## Improvement suggestions

- P1: dispatch requirement files in parallel when a run has six independent stories.
- P2: re-run `npm audit` at the start of a dependency unit's planning, not only at P0. Backlog `0000010` tracks this.
- P3: record each MCP call as it happens. The P3 count of 20 is an estimate from the session.

## Postmortems

- `plan/postmortems/2026-10-31-advisory-after-discovery.md`

## Workflow governance

| Metric | Value | Threshold | Result |
|--------|-------|-----------|--------|
| Rework loops per requirement (highest) | 0 | 2 | ok |
| `Blocked:` stops | 1 | 1 | ok |
| Mid-pipeline design changes | 0 | 1 | ok |
| Human corrections at gates | 0 | 2 | ok |

Breaches: 0. The gate reports and does not block. Counts come from marker lines only.
Retrospective: plan/retrospectives/0000009-bug-fixes-2026-10-31.md
