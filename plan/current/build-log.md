---
title: "Build Log - 0000005-ravintio-docs-rewrite"
summary: "Working record of the pipeline run, maintained by the orchestrator."
---
# Build Log - 0000005-ravintio-docs-rewrite

> Created at discovery (P0). Appended by the orchestrator at each phase boundary. Survives session changes.

## Header

| Field | Value |
|-------|-------|
| Feature ID | `0000005-ravintio-docs-rewrite` |
| Pipeline start | `2026-10-28T23:59:41Z` |
| Tool | `claude-code` |
| Primary model | `claude-opus-5-5` |
| Cheaper model | `claude-sonnet-5-5` |
| Run speed | `standard` |

---

## Phase Log

### P0: Discovery

| Field | Value |
|-------|-------|
| Start | `2026-10-28T23:59:41Z` |
| End | |
| Wall clock | |
| Model tier | primary |
| Skills loaded | ravintio-orchestrator, ravintio-migrator |
| Agents spawned | `0` |
| MCP calls | `0` |
| Parallel task batches | `0` |
| Notes | See the discovery notes below. |

#### Discovery notes

- Migration 0005 skipped: its `Applies when:` condition is false in this repo. It stays pending.
- Pre-flight: branch cut from `main`. Pack swap committed as `7a1cb5f`.
- Stale `plan/.run-mode` (value `continuous`, not a valid mode) deleted.
- Product id confirmed by the human: `ravintio-docs`. Written to `product.yml`.
- Adoption mode assumed: Standard Iterative. Signal: `plan/_archive/` holds 3 runs beside `src/`.
- Backlog `0000004-ravintio-rebrand`: pulled in. Folder deleted in the discovery commit.
- Remote `origin` set to `git@github.com:RAVINTIO/ravintio-docs.git`. The GitHub repo rename is the human's action.

#### Coaching log

P0 exchange (version): Q: Release version, 1.0.0 (breaking) or 0.4.0? / A: Minor bump. Confirmed version 0.4.0, against a recommendation of 1.0.0.
P0 exchange (content source): Q: none (human-initiated) / A: The human supplied a private RAVINTIO technical strategy as the starting guidance. The strategy stays private and is not committed. The site must explain RAVINTIO.
P0 exchange (site scope): Q: Overview for all six tools plus full Zero docs, or also full Framework docs? / A: Overview for all six plus full Zero docs first. Framework docs deferred to backlog 0000006.
P0 exchange (audience): Q: Primary reader a developer with a coding agent deciding whether to adopt Zero, journey understand, install, first run? / A: Agreed. Catalogue material moves to a reference section.
P0 exchange (page structure): Q: Ten pages in three sections (RAVINTIO 1-2, Zero 3-7, Reference 8-10), delete routing, change pipeline, and fast path? / A: Confirmed.
P0 exchange (rename visibility): Q: (human-initiated) Is the site explaining the rename? / A: Remove any such explanation. Nobody has used Planifest, so no page names or references it. The brand guard test enforces zero Planifest mentions in published content.
P0 exchange (content source): Q: (human-initiated) Reuse old pages? / A: No. The old docs were poor. Delete all old copy and write new content. Sources are the private strategy (public parts only) and the current Zero pack and repo, never the old pages.
P0 exchange (decomposition): Q: One run with releaseSize large (12 of 14 points) or two runs? / A: One run. releaseSize set to large in product.yml.
P0 exchange (acceptance criteria): Q: Seven criteria (build and nav, no Planifest, RAVINTIO capitals, no private sections, reference matches pack, links resolve, sentence and blocklist rules)? / A: Confirmed. Criterion 4 is a human checklist review. The rest are automated.
P0 exchange (component design): Q: One component site-content at src/site-content/ (pages/, docs/, component.yml), delete both planifest-docs folders, web-app reads only? / A: Confirmed.
P0 exchange (unbuilt tools): Q: Status label per tool (Zero and Framework Available, Accept, Qualify, Insight In design, Unbound In design experimental), purpose and boundaries only, no dates or promises? / A: Confirmed as shown.
P0 exchange (scope and logo): Q: Scope as shown with a text wordmark, or a supplied logo? / A: Human supplied a RAVINTIO logo, a teal R on white. Saved as graphics/ravintio-logo.png. Scope otherwise as shown.
P0 exchange (non-functional): Q: WCAG 2.2 AA, page weight under 300 KB excluding mermaid, no horizontal scroll at 360 px, build under 60 s in CI? / A: Confirmed, all four.
P0 exchange (operations): no question asked. Deployment stays on the existing deploy.yml push-to-main workflow. A static site has no SLO, alerting, or runtime cost beyond GitHub Pages.
Scope Lock (happy path): A developer reads What is RAVINTIO, picks Zero, follows Install Zero and Your first run, and raises a first PR using only the site. [source: draft-accepted]
Scope Lock (first-run path): A reader new to RAVINTIO meets the name and the six tools before any command. The first deploy after the repo rename serves the new address with no Planifest page. [source: draft-accepted]
Scope Lock (error path): Pack drift fails the build through the reference-match test, so stale pages never deploy. Old Planifest links reach a 404, accepted with no redirects. [source: draft-accepted]
Scope Lock (cross-session continuity): Not applicable. The site is static and keeps no reader state. [source: draft-accepted]
Scope Lock complete. All four scenario paths captured. The human answered "Accept all", taken as an explicit accept of each item.
