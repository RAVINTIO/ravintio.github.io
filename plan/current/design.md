# Design - 0000016-site-regression-and-quality

## Feature
- Problem: contributors to the RAVINTIO docs site have no browser tests, no tests in CI, and no regular quality review. A reader on the dark theme sees a light frame on every page load.
- Adoption mode: standard-iterative (assumed, the only signal: `plan/_archive/` holds feature dirs and `docs/about.md` exists)
- Feature ID: 0000016-site-regression-and-quality
- Version: `0.5.0`, a minor bump from `0.4.1`. `web-app` goes to `0.5.0`. `site-content` stays at `0.4.1` unless the quality review changes a page.
- Discovery: see `plan/current/discovery.md` (raw discovery findings. Do not embed them here. This document records confirmed decisions only)

## Product Layer
- User stories:
  - US-001: As a contributor, I run a Playwright suite that loads every page in a real browser, so that broken pages, links, and mobile layouts show before merge.
  - US-002: As a contributor, I run Playwright tests on the site's interactive parts, so that the theme toggle, the mobile page list, and diagrams keep working.
  - US-003: As a reviewer, I see both test suites run on each pull request, so that I know the site builds and passes before I merge.
  - US-004: As a contributor, I get Playwright MCP from the repo's own config, so that every session in this repo has the same browser tools.
  - US-005: As the maintainer, I get a site quality review in P3 of every run, so that urgent defects get fixed and other improvements reach the backlog.
  - US-006: As a reader, I see my chosen theme from the first frame, so that pages don't flash white on load.
- Acceptance criteria (17):
  - US-001
    - AC-1: each manifest page and the homepage return status 200 and log no console errors.
    - AC-2: each internal link and anchor on those 11 pages resolves.
    - AC-3: no page scrolls sideways at a 390 px viewport.
  - US-002
    - AC-1: the theme toggle switches the theme, and the choice persists across a reload, on the homepage and a doc page.
    - AC-2: the page list is collapsed at 390 px and opens on click. At 1280 px it shows open.
    - AC-3: each Mermaid diagram renders as an SVG.
  - US-003
    - AC-1: `site-tests.yml` runs on each pull request into `main`. It builds the site, then runs the `node --test` suite and the Playwright suite.
    - AC-2: when a Playwright test fails, the job fails and uploads the Playwright report as an artefact.
    - AC-3: the Playwright suite runs in under 60 s locally against a build. The CI job runs in under 5 min. Three consecutive runs with `retries: 0` all pass.
  - US-004
    - AC-1: `.mcp.json` at the repo root declares a `playwright` server that runs `@playwright/mcp` at exactly `0.0.83`.
  - US-005
    - AC-1: repo instruction `custom-003-site-quality-review.md` runs the `site-quality-review` capability skill in P3, after the Playwright suite passes.
    - AC-2: the skill writes `plan/current/site-quality-report.md`. The report covers five areas, each with its target: accessibility (WCAG 2.2 AA), layout (390 px and 1280 px, both themes), content (repo style and pack facts), performance (page weight under 500 KB, LCP under 2.5 s on the preview), and navigation and metadata.
    - AC-3: the skill sorts each finding as fix-now or backlog by the confirmed rule. It stops and asks when fix-now work passes 2 points. It adds evidence to a matching backlog entry instead of filing a duplicate.
  - US-006
    - AC-1: with dark saved, the first painted frame is dark on the homepage and on a doc page.
    - AC-2: with light saved, the first painted frame is light on both pages.
    - AC-3: with no saved choice, the first frame follows the operating system preference.
- Fix-now rule (US-005): a finding is fix-now when any of these is true.
  - The current run caused it.
  - It fails WCAG 2.2 level A.
  - A link or anchor is broken, or a page logs a console error.
  - A page breaks at 390 px, with overlap, clipping, or horizontal scroll.
  - Every other finding becomes a `plan/backlog/` entry with the page, the area, the evidence, and a suggested fix.
- Constraints:
  - Playwright runs Chromium only.
  - The existing `node --test` suite stays as it is.
  - The quality review adds no dependency beyond Playwright MCP.
  - The review navigates only to the local `vite preview` server.
- Integrations: GitHub Actions (new `site-tests.yml`), Playwright MCP (local agent sessions).

## Architecture Layer
- Latency target: not applicable to a static site. Performance targets for the review: page weight under 500 KB, LCP under 2.5 s on the local preview.
- Availability target: unchanged, GitHub Pages.
- Scalability target: not applicable.
- Test run-time targets: Playwright suite under 60 s locally, `site-tests.yml` job under 5 min, 0 flaky tests over 3 runs with `retries: 0`.
- Security: no authentication. The site and its data are public. The `site-tests.yml` workflow gets `contents: read` permission only. Playwright MCP gives the agent a browser, so the review limits navigation to the local preview origin.
- Data privacy: no regulated data.
- Observability: Playwright HTML report and traces on failure, kept as a CI artefact. The quality report is kept in the run archive.
- Cost boundary: GitHub Actions minutes on the free tier for a public repo.

## Engineering Layer
- Stack: TypeScript, Vite 7, `marked`, `mermaid` 12. Tests: `node --test` plus `@playwright/test` on Chromium. CI: GitHub Actions. Build target: local.
- Components:
  - `web-app` (existing): builds and serves the site. It now also owns the Playwright suite, its config, and the white flash fix.
  - `site-content` (existing): owns the page Markdown. It changes only if a fix-now finding needs a page change.
  - Repo-level config (not a component): `.mcp.json`, `.github/workflows/site-tests.yml`, `ravintio-overrides/instructions/custom-003-site-quality-review.md`, and `ravintio-overrides/capability-skills/site-quality-review/`.
- Data ownership:
  - `src/site-content/pages/*.md`: `site-content`.
  - `src/web-app/tests/e2e/`, `playwright.config.ts`, templates, and scripts: `web-app`.
  - `plan/current/site-quality-report.md` and review backlog entries: the pipeline run.
- Dependency order: `web-app` changes (US-001, US-002, US-006) land before CI (US-003). The quality review (US-005) runs last, in P3.
- Deployment: unchanged. `deploy.yml` builds and publishes to GitHub Pages on a push to `main`.
- API versioning: not applicable.
- New ADR: Playwright joins `node --test` for browser tests. It supersedes 0000005 ADR-001, which kept all tests on `node --test` with no new dependency.

## Scope
- In:
  - `.mcp.json` with a pinned Playwright MCP.
  - A Playwright regression suite in `src/web-app`.
  - `site-tests.yml` on pull requests.
  - The `site-quality-review` capability skill and repo instruction `custom-003`.
  - The first quality review, in this run's P3.
  - The white flash fix.
- Out:
  - Firefox and WebKit.
  - Visual snapshot comparison.
  - Changes to `deploy.yml` or `ravintio.yml`.
  - Making `site-tests.yml` a required check. That's a GitHub setting for the human.
- Deferred:
  - Framework user docs: backlog 0000014. Framework is under major rework.
  - axe-core scans: backlog 0000015.

## Assumptions
- The white flash comes from the deferred module script that sets `data-theme` - impact if wrong: the inline script fixes nothing, and US-006 needs a new cause. The suite tests this before the fix.
- A first-frame check in Playwright can tell a light frame from a dark one - impact if wrong: US-006 falls back to checking `data-theme` and the computed background before the module script runs.
- Playwright MCP stays available in the P3 session - impact if wrong: the review stops with a `Blocked:` line.

## Risks
- The first-frame test is flaky because paint timing varies. Likelihood medium, impact medium. Mitigation: check the theme state the inline script sets before any stylesheet, not a screenshot.
- The first review finds more fix-now work than the run can hold. Likelihood medium, impact medium. Mitigation: the 2-point cap stops and asks.
- A Playwright MCP upgrade changes tool names and breaks the skill. Likelihood low, impact low. Mitigation: the exact pin.
- The review's backlog entries flood the backlog. Likelihood low, impact low. Mitigation: the duplicate check.

## Dependencies
- Upstream: GitHub Actions, npm registry, Playwright's Chromium download.
- Downstream: backlog 0000014 (Framework docs) uses the suite for its new pages.
- Approved dependencies:
  - `@playwright/test` `1.64.1`, exact, `src/web-app` dev dependency. Patch updates within `1.64.x` are allowed.
  - `@playwright/mcp` `0.0.83`, exact, run through `npx` from `.mcp.json`.
  - Chromium, installed by `npx playwright install chromium`.

## Active Skills
None installed. This run creates `site-quality-review` in `ravintio-overrides/capability-skills/`.

## Skill Map
| Requirement | Best-fit Skill | Rationale |
|-------------|----------------|-----------|
| US-001 - page health suite | ravintio-implement | New Playwright tests and config through the TDD loop |
| US-002 - interactive behaviour suite | ravintio-implement | Browser tests for the toggle, page list, and diagrams |
| US-003 - CI workflow | ravintio-implement | One workflow file, checked by a `node --test` test on its content |
| US-004 - Playwright MCP config | ravintio-implement | One config file with a content test |
| US-005 - site quality review | ravintio-implement, then ravintio-validate-and-accept | Implement writes the skill and instruction. P3 runs the first review. |
| US-006 - no white flash | ravintio-implement | The US-002 suite gives the RED test before the fix |

## Repo Instructions
### custom-002-push-and-raise-prs.md
You may fetch, pull, and push feature branches, and raise pull requests into `main` with `gh pr create`. Never merge a pull request into `main`, and never push to `main` directly. The human reviews and merges every pull request. Work on a `feat/` branch directly in the working directory. Don't use git worktrees. If a push or `gh` command fails, report the exact error and stop. Never retry with force.

## Confirmation
Human confirmed this design before proceeding: yes // Date and Time confirmed: 01 Nov 2026 @ 08:55 UTC
