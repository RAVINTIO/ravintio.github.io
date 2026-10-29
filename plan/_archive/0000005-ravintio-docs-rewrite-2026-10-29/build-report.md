# Build Report - 0000005-ravintio-docs-rewrite

**Run speed:** standard
**Run mode:** autonomous

## Phases

| Phase | Agents | Model tier | Wall clock (min) | Parallel batches | Self-corrections |
|-------|--------|------------|------------------|------------------|------------------|
| P0 Discovery | 0 | primary | 1230 | 0 | 0 |
| P1 Plan | 0 | primary | 3 | 0 | 0 |
| P2 Implement | 6 (sonnet) | primary | 17 | 2 | 0 |
| P3 Validate and Accept | 0 | primary | 2 | 0 | 1 |
| P4 Ship | 0 | primary | 0 | 0 | 0 |

P0's wall clock covers the time between the human's answers, across two calendar days. It doesn't measure agent work.

## Parallelism

- P2 ran three page-writing units in one batch, then two fix units in one batch.
- P1 ran inline. Its artefacts were small and shared one context.
- P3 ran its checks in order. Browser verification and the security scans were short enough that splitting them would have saved little.

## Self-corrections

- P3 cycle 1: `templates.html` scrolled sideways at 360 px. Long file names in code font didn't wrap. Avoidable: the style test covers sentence length but no layout check ran in P2.

## Improvement suggestions

- **P0:** ask the content-source question first. The human supplied the strategy and the no-reuse rule after two structure questions, which forced a re-size.
- **P2:** run a 360 px layout check in P2, not only in P3.
- **P2:** brief page writers with the pack facts that a reviewer later corrected, such as setup side effects and the hard limits. The review cycle found 20 issues.

## Postmortems

Postmortems: none

## Workflow governance

| Metric | Value | Threshold | Result |
|--------|-------|-----------|--------|
| Rework loops per requirement (highest) | 0 | 2 | ok |
| `Blocked:` stops | 0 | 1 | ok |
| Mid-pipeline design changes | 0 | 1 | ok |
| Human corrections at gates | 0 | 2 | ok |

Breaches: 0. The gate reports and does not block. Counts come from marker lines only.

Retrospective: none. The run did not invoke `ravintio-retrospective`.
