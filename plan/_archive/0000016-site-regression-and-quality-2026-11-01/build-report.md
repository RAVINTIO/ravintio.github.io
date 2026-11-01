# Build Report - 0000016-site-regression-and-quality

**Run speed:** standard

## Phases

| Phase | Agents | Model tier | Wall clock (min) | Parallel batches |
|-------|--------|------------|------------------|------------------|
| P0 Discovery | 0 | primary | 875 | 0 |
| P1 Plan | 0 | primary | 421 | 0 |
| P2 Implement | 4 (`sonnet`: three TDD tracks and one reviewer) | primary | 8 | 2 |
| P3 Validate and Accept | 0 | primary | 5 | 0 |
| P4 Ship | 0 | primary | 0 | 0 |

P0 and P1 wall clock include time spent waiting on the human. The P0 figure spans an overnight break. The P1 figure includes the US-002 AC-3 stop.

## Parallelism

- P1 wrote six requirements, four ADRs, and the plan set inline. The build log records the departure.
- P2 ran batch 1 with U1 and U6 as parallel subagents and U2 inline. Batch 2 ran U4 then U3 in one subagent, with U5 inline beside it. U4 and U3 ran in sequence because both use `dist/` and port 4173.
- P3 ran its checks in sequence. The review and the execution checks shared one preview server.

## Self-corrections

| Phase | Self-correction | Avoidable |
|-------|-----------------|-----------|
| P2 | Setup installs only `SKILL.md`, so the review skill now reads its report template from `ravintio-overrides/` | Yes. The brief could have checked how setup copies capability skills. |
| P2 | The list reporter hides skip reasons, so REQ-002 AC-3 prints its reason | Yes. A reporter check before writing the criterion would have caught it. |
| P2 | Improvement cycle 1: `appType: 'mpa'` for missing pages, plus tighter REQ-006 AC-1 and AC-2 tests | Partly. The missing-page case needed a fresh view of `vite preview`. |
| P3 | `.playwright-mcp/` added to `.gitignore` (review finding N-003, `Rework: REQ-004`) | Yes. REQ-004 could have named the MCP output folder. |

## Improvement suggestions

- P1: when a criterion depends on site content, check that the content exists before writing it. REQ-002 AC-3 needed a P1 stop because no page holds a diagram.
- P2: brief each subagent on shared resources such as `dist/` and fixed ports, so the concurrency plan accounts for them.
- P3: record each MCP call as it happens. The count of 16 is a tally from this session.

## Postmortems

Postmortems: none

## Workflow governance

| Metric | Value | Threshold | Result |
|--------|-------|-----------|--------|
| Rework loops per requirement (highest) | 1 (REQ-004) | 2 | ok |
| `Blocked:` stops | 1 | 1 | ok |
| Mid-pipeline design changes | 1 | 1 | ok |
| Human corrections at gates | 0 | 2 | ok |

Breaches: 0. The gate reports and does not block. Counts come from marker lines only.
