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
P0 exchange (copy bug 1): Q: (human-initiated) The "The name" section on what-is-ravintio is on the nose. Developers want to know why to use RAVINTIO. What replaces it? / A: Confirmed after two revisions. New opening paragraph says what RAVINTIO does. "The name" becomes "Why use RAVINTIO", one benefit-led list of nine items: designed before built, follows your standards, docs with the code, decisions on record, constraints hold, done means proven, failures get fixed, work survives a new session, no lock-in. Letter table and the block-capitals instruction removed. "Shared design principles" trimmed to human authority, blameless learning, and assessment that challenges the work. Human correction: outputs (standardised docs, decision records, constraint adherence) and designing changes to standards are reasons to adopt, not a separate list.
P0 exchange (copy bug 2): Q: (human-initiated) Guidance on keeping solutions simple and avoiding unmanageable complexity is missing. Proposal: a "Solutions stay as simple as the problem allows" bullet in what-is-ravintio's "Why use RAVINTIO" after "Constraints hold". A "How Zero keeps solutions simple" section in zero-overview covering discovery release sizing, plan deriving only stated requirements and ADR downsides, implement minimum code plus improvement loop, and code-quality standards. One sentence in pipeline P2 on the improvement loop's purpose. / A: Confirmed.
P0 exchange (site review): Q: (human-initiated) Review the rest of the site against the guidance so it works for a developer using RAVINTIO. Proposal: 1. first-run step 2 adds mkdir -p plan/current before the cp, since setup does not create it. 2. zero-overview leads with why and how a run flows, glossary moves to the end. 3. zero-overview "Why Zero exists" becomes Zero-specific benefits, pointing back to the RAVINTIO list. 4. "Limits of Zero" becomes "When Zero fits", benchmark line dropped. 5. install-zero drops "The pack states no minimum version". 6. first-run "What you have now" adds what the outputs give you. 7. six-tools "What it owns" and "What it doesn't replace" become "What it does" and "What it works alongside". 8. index.html hero subtitle becomes "Coding agents that build to your design and standards, and prove the result." Reference pages, pipeline, and project-operations unchanged. / A: Agreed, all eight.
P0 exchange (backlog 0000006): Q: Leave, pull in, or discard 0000006-framework-docs? Recommended leave. / A: Leave for now.
P0 exchange (dependencies): Q: none (finding) / A: npm audit fix clears all 16 advisories within current majors, vite 7.3.7 and mermaid 11.17.2. No new dependency.
P0 exchange (version): Q: Patch 0.4.1 or minor 0.5.0? Recommended 0.4.1. / A: 0.4.1 agreed.
P0 exchange (mobile nav): Q: Collapsed disclosure above the content, or move the page links into the menu, below 900 px? / A: Collapsed disclosure, closed by default, showing the current page.
P0 exchange (stories and criteria): Q: Six stories US-001 to US-006 with 13 acceptance criteria, 9 of 14 points, one run? / A: Confirmed.
Scope Lock (happy path): The developer reads "Why use RAVINTIO" first, follows overview, install, and first run with every command working, and on a phone sees the page list closed above the content. [source: draft-accepted]
Scope Lock (first-run path): On a fresh setup, mkdir -p plan/current precedes the cp, so the copy succeeds. On first phone load the disclosure starts closed and names the current page. [source: draft-accepted]
Scope Lock (error path): If npm audit fix changes built output or breaks a test, the unit stops and reports. No major bump, no loosened test. Without JavaScript or CSS, the page list renders as a plain list. [source: draft-accepted]
Scope Lock (cross-session continuity): No reader state. Each page lands in its own commit, so an interrupted run resumes at the next unit. The disclosure starts closed on every load. [source: draft-accepted]
