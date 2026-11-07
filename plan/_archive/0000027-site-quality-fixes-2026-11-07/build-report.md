# Build report - 0000027-site-quality-fixes

Run speed: fast. Run mode: autonomous.

## Per phase

| Phase | Agents | Model tier | Wall clock (min) | Notes |
|-------|--------|------------|------------------|-------|
| P0 Discovery | 0 | primary | 108 | Includes the waits for the human at backlog pickup and the design gate |
| P1 Plan | 0 | primary | 1 | Artifacts written inline |
| P2 Implement | 4 | primary `sonnet` | 12 | Three parallel TDD tracks, four inline units, and one review |
| P3 Validate and Accept | 3 | primary `sonnet` | 9 | Verification and security in parallel, then the quality review |
| P4 Ship | 0 | primary | 0 | The P4 block closed before the archive, retrospective, and PR, so the figure undercounts |

## Parallelism

- P2 batch 1 ran U1, U2, and U3 as three agents in one message.
- P3 ran execution verification and the security review in one message.
- P2 batches 2 to 5 ran inline, one unit each. Each batch held one unit, because the units shared `dist/`, port 4173, or a file.
- P1 wrote its artifacts inline. Each unit was one short file from criteria in the design.
- P4 wrote this report inline instead of in a cheaper-tier agent.

## Self-corrections

| Correction | Avoidable |
|------------|-----------|
| P2: the phone width test failed on the sitemap after U7 added the sitemap to `pagePaths()`, and the run's own check missed it | Yes. A `tail -2` on the Playwright output hid the failed line. The improvement review caught it. |
| P3: three criteria had no test named for them | Yes. The test-writer named only the first criterion when one test covered three. |
| P3: the skip link left focus on itself (WCAG 2.4.1) | No. The fault predates this run, and only a keyboard check found it. |

## Improvement suggestions

- P2: read the pass, fail, and skip counts from test output, never only its last lines.
- P2: when one test covers several criteria, name each criterion in the test title.
- P3: give the verification agent leave to make temporary edits to any file it restores, so it can prove every failure path.

## Postmortems

Postmortems: none.
## Workflow governance

| Metric | Value | Threshold | Result |
|--------|-------|-----------|--------|
| Rework loops per requirement (highest) | 1 (REQ-003) | 2 | ok |
| `Blocked:` stops | 0 | 1 | ok |
| Mid-pipeline design changes | 0 | 1 | ok |
| Human corrections at gates | 0 | 2 | ok |

Breaches: 0. The gate reports and does not block. Counts come from marker lines only.
