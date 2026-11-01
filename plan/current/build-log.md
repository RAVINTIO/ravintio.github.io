---
title: "Build Log - 0000016-site-regression-and-quality"
summary: "Working record of the pipeline run, maintained by the orchestrator."
---
# Build Log - 0000016-site-regression-and-quality

> Created at discovery (P0). Appended by the orchestrator at each phase boundary. Survives session changes.

## Header

| Field | Value |
|-------|-------|
| Feature ID | `0000016-site-regression-and-quality` |
| Pipeline start | `2026-10-31T18:19:38Z` |
| Tool | `claude-code` |
| Primary model | `claude-opus-5-5` |
| Cheaper model | `claude-sonnet-5-5` |
| Run speed | `standard` |

---

## Phase Log

### P0: Discovery

| Field | Value |
|-------|-------|
| Start | `2026-10-31T18:19:38Z` |
| End | `2026-11-01T08:55:35Z` |
| Wall clock | `875` |
| Model tier | primary |
| Skills loaded | ravintio-orchestrator, ravintio-migrator, ravintio-file-backlog |
| Agents spawned | `0` |
| MCP calls | `0` |
| Parallel task batches | `0` |
| Notes | none |

- Pre-flight: started on `feat/0000009-bug-fixes`. PR 24 merged as `ec07aad`. Switched to `main`, pulled, and created `feat/pending`. Deleted the merged local branch `feat/0000009-bug-fixes` at the human's request.
- Migration 0005: `Applies when:` is false. The repo has no `plan/roadmap/*/roadmap.md` and no `roadmap/**` in `ravintio.yml`. Left pending.
- Pack update check: resume detection compared pack `0.37.0` with the product version `0.4.1`. This is the false positive ruled in run 0000009. No `ravintio-zero/` file changed since `54db2ef`.
- Backlog: discarded 0000010, 0000011, and 0000012. Each is a pack change that Zero had not logged and still needs. Moved to the Zero repo as uncommitted entries 0000328, 0000329, and 0000330.
- Backlog: pulled in 0000006 and 0000013, folded into `feature-brief.md`. Repointed the 0000009 retrospective and postmortem links to the Zero ids.
- Scope: the human added a third item, Playwright MCP, a Playwright regression suite, and a site quality review each run.
- P0 exchange (release size): Q: the items come to about 16 points against 14. Split Framework docs out? / A: yes. Framework is under major rework, so its docs wait anyway. Re-filed as a new backlog entry.
- P0 exchange (MCP scope): Q: check in a project `.mcp.json` with `@playwright/mcp` pinned, or leave it at user scope? / A: project `.mcp.json`, pinned.
- P0 exchange (suite coverage): Q: page loads with no console errors, internal links and anchors, theme toggle and persistence, no light frame before dark, page list at 900 px, Mermaid renders, no horizontal scroll at 390 px. Chromium only, against `vite preview`? / A: confirmed as proposed.
- P0 exchange (CI): Q: CI runs no tests today. Add `site-tests.yml` on pull requests into `main` to build, run `node --test`, run Playwright, and upload the report on failure? / A: confirmed.
- P0 exchange (review mechanism): Q: a permanent `site-quality-review` capability skill plus repo instruction `custom-003-site-quality-review.md` that runs it in P3 after the suite passes, writing `plan/current/site-quality-report.md`? / A: confirmed.
- P0 exchange (review areas): Q: accessibility (WCAG 2.2 AA, from the accessibility tree), layout (390 px and 1280 px, both themes), content (repo style, pack facts), performance (weight under 500 KB, LCP under 2.5 s on preview), navigation and metadata. No new dependency, `axe-core` deferred? / A: confirmed.
- Backlog: filed axe-core scans at the human's request.
- P0 exchange (triage rule): Q: fix-now when the run caused it, it fails WCAG 2.2 A, a link, anchor, or console error, or a 390 px break. All else to the backlog. Stop and ask above 2 points of fix-now work. Add evidence to a matching entry instead of a duplicate? / A: confirmed.
- P0 exchange (white flash): Q: inline theme script at the top of `<head>`, a `color-scheme` meta tag, `main.ts` keeps the toggle. Criteria: first frame matches saved dark, saved light, and the OS preference with no saved choice, on the homepage and a doc page? / A: confirmed.
- P0 exchange (dependencies): Q: approve `@playwright/test` `1.64.1` (dev) and `@playwright/mcp` `0.0.83` (skipping `0.0.84`, released today on a `1.65.0` alpha), exact pins, patch updates within `1.64.x` allowed? / A: agreed.
- P0 exchange (NFRs): Q: Playwright suite under 60 s locally, `site-tests.yml` under 5 min in CI, 0 flaky tests over 3 runs with `retries: 0`? / A: confirmed.
- P0 exchange (version): Q: `0.5.0`, a minor bump. `web-app` to `0.5.0`, `site-content` stays `0.4.1` unless the review changes a page? / A: confirmed.
- P0 exchange (feature id): Q: `0000016-site-regression-and-quality`? / A: confirmed. Branch renamed from `feat/pending`.
Scope Lock (happy path): PRs run both suites in `site-tests.yml`, P3 runs the quality review and files or fixes findings, and dark readers see no light frame. [source: draft-accepted]
Scope Lock (first-run path): Chromium installs once locally and in CI, the first review treats all findings as new, and `.mcp.json` prompts once. [source: draft-accepted]
Scope Lock (error path): a red test fails the PR check with the report as an artefact, a missing MCP blocks P3, and fix-now work over 2 points stops for the human. [source: draft-accepted]
Scope Lock (cross-session continuity): the review writes as it goes, an `In progress:` marker reruns it, and the duplicate check prevents double filing. [source: draft-accepted]
Scope Lock complete. All four scenario paths captured.
Run mode: autonomous (2026-11-01T03:10:57Z)
Run speed: standard (2026-11-01T08:55:00Z)
Design confirmed: 2026-11-01T08:55:35Z

---

### P1: Plan

| Field | Value |
|-------|-------|
| Start | `2026-11-01T08:56:06Z` |
| End | `2026-11-01T15:57:56Z` |
| Wall clock | `421` |
| Model tier | primary |
| Skills loaded | ravintio-plan |
| Agents spawned | `0` |
| MCP calls | `0` |
| Parallel task batches | `0` |
| Notes | none |

- Departure: the plan artifacts run inline, not as parallel subagents. Six short requirements share one design and many cross-references, so a subagent brief would repeat most of the design.
- Blocked: US-002 AC-3 has nothing to test. No page in `src/site-content/pages/` holds a Mermaid diagram. (2026-11-01T15:55:10Z)
- Requirement change: cosmetic: US-002 AC-3 reworded to check diagrams when a page holds one and report a named skip when none does. Re-ran nothing. (2026-11-01T15:55:10Z)
- Resolved: the human chose the reworded criterion with a reported skip. (2026-11-01T15:55:10Z)
- Consistency check: clean.

---

### P2: Implement

| Field | Value |
|-------|-------|
| Start | `2026-11-01T15:58:40Z` |
| End | `2026-11-01T16:07:02Z` |
| Wall clock | `8` |
| Model tier | primary (orchestrator), primary `sonnet` (TDD tracks) |
| Skills loaded | ravintio-implement |
| Agents spawned | `4` |
| MCP calls | `0` |
| Parallel task batches | `2` |
| Notes | none |

- Departure: each unit runs as one TDD track (test-writer, implementer, and refactor in sequence) in one `sonnet` subagent, not three subagents. The improvement loop runs as one fresh-context review across the whole diff, as the 0000009 retrospective recommends. Pack backlog 0000330 covers this gap in Zero.
- Departure: U2 runs inline in the orchestrator. It is one config file and one parse test, and a subagent brief would be longer than the unit.
- In progress: U1 REQ-001 TDD track (2026-11-01T15:58:40Z)
- In progress: U2 REQ-004 TDD track (2026-11-01T15:58:40Z)
- In progress: U6 REQ-005 TDD track (2026-11-01T15:58:40Z)
- U2 REQ-004: RED exit 1 (`.mcp.json is missing at the repo root`), GREEN exit 0. Refactor: no change worth making.
- Done: U2 REQ-004 TDD track (2026-11-01T16:00:00Z)
- U6 REQ-005: RED exit 1 (`custom-003-site-quality-review.md is missing`), GREEN exit 0, 7 of 7 tests. Setup re-run with `--strict-orchestrator` installed the skill and the instruction. Setup copies only `SKILL.md`, so the skill now reads its report template from the source path.
- Done: U6 REQ-005 TDD track (2026-11-01T16:00:58Z)
- U1 REQ-001: RED exit 1 (`npx canceled due to missing packages`), GREEN exit 0, 23 of 23 tests. Three runs: 5.4 s, 2.2 s, and 2.3 s. `npm test` 49 of 49. No site defect found.
- Done: U1 REQ-001 TDD track (2026-11-01T16:01:18Z)
- Departure: batch 2 runs U4 then U3 in one subagent, not in parallel. Both rebuild `dist/` and start `vite preview` on port 4173, so parallel runs would clash. U5 runs inline in parallel with them.
- In progress: U4 REQ-006 TDD track (2026-11-01T16:01:18Z)
- In progress: U3 REQ-002 TDD track (2026-11-01T16:01:18Z)
- In progress: U5 REQ-003 TDD track (2026-11-01T16:01:18Z)
- U5 REQ-003: RED exit 1 (`site-tests.yml is missing`), GREEN exit 0, 4 of 4 tests. Refactor: no change worth making. CI timing (AC-3) is measured on the PR in P3.
- Done: U5 REQ-003 TDD track (2026-11-01T16:02:04Z)
- U4 REQ-006: RED exit 1, 6 of 6 failing (`data-theme` received `undefined` with module scripts blocked). GREEN exit 0, 6 of 6. Refactor: no change worth making.
- Done: U4 REQ-006 TDD track (2026-11-01T16:04:51Z)
- U3 REQ-002: RED shown by mutation for each criterion. GREEN: 33 passed and 1 skipped, three runs of 2.7 s, 2.3 s, and 2.4 s. The list reporter hides skip reasons, so the orchestrator added a printed reason to AC-3.
- Done: U3 REQ-002 TDD track (2026-11-01T16:04:51Z)
- In progress: U7 docs close-out (2026-11-01T16:04:51Z)
- U7: `web-app` to `0.5.0` in `component.yml`, `package.json`, and `package-lock.json`. Updated the component docs, the four living docs, and the decisions index. Drift fixed: `architecture-overview.md` listed `mermaid` 11, not 12. Change record written.
- Done: U7 docs close-out (2026-11-01T16:05:05Z)
- Improve: cycle 1, fresh-context review of the whole diff. Three findings, all applied:
  - `vite preview` fell back to the homepage with status 200 for a missing page, so the link check passed a broken page link. Set `appType: 'mpa'` in `vite.config.ts`. A broken link injected into the build now fails AC-2.
  - REQ-006 AC-2 ran under a light system preference, so it couldn't tell a saved `light` from the fallback. It now runs under a dark preference. Dropping the `light` branch now fails it.
  - REQ-006 AC-1 accepted a dark background on either `<html>` or `<body>`. It now checks `<body>`, which `style.css` sets.
  Stopped after one cycle: the three fixes were the reviewer's whole list. (2026-11-01T16:06:54Z)

---

### P3: Validate and Accept

| Field | Value |
|-------|-------|
| Start | `2026-11-01T16:07:30Z` |
| End | `2026-11-01T16:12:54Z` |
| Wall clock | `5` |
| Model tier | primary |
| Skills loaded | ravintio-validate-and-accept, site-quality-review |
| Agents spawned | `0` |
| MCP calls | `16` |
| Parallel task batches | `0` |
| Notes | none |

- CI: library audit pass (Playwright is the pack's preferred E2E framework), `tsc --noEmit` pass, build pass, `npm test` 53 of 53, `npm run test:e2e` 33 passed and 1 skipped, `npm audit` 0 vulnerabilities. No lint step is declared. Self-correct cycles: 0.
- Execution: Playwright MCP drove the preview at 390 px and 1280 px in both themes. See `verification-report.md`.
- In progress: site quality review (2026-11-01T16:08:54Z)
- Rework: REQ-004: the Playwright MCP browser writes snapshots and screenshots to `.playwright-mcp/` in the repo root, which git did not ignore. Added it to `.gitignore`. Quality review fix-now finding N-003, size S. (2026-11-01T16:10:53Z)
- Site quality review: 11 pages, 1 fix-now finding (fixed, 1 point) and 5 backlog findings filed as 0000017 to 0000021. Report in `site-quality-report.md`.
- Done: site quality review (2026-11-01T16:11:30Z)
- Security review: overall low. No critical, high, or medium finding. Three low findings and two informational ones, in `security-report.md`.
- Verification: 15 criteria verified, with REQ-003 AC-3 verified locally. REQ-003 AC-1 and AC-2 are not-verifiable until the pull request runs CI.
- Backlog: filed security finding S-001 as 0000022.
- Acceptance evidence written. Autonomous run, so no gate stop.

---

### P4: Ship

| Field | Value |
|-------|-------|
| Start | `2026-11-01T16:13:21Z` |
| End | `{{timestamp, filled when the phase completes}}` |
| Wall clock | `{{whole minutes from Start to End}}` |
| Model tier | primary |
| Skills loaded | ravintio-ship, ravintio-retrospective |
| Agents spawned | `0` |
| MCP calls | `0` |
| Parallel task batches | `0` |
| Notes | none |

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
