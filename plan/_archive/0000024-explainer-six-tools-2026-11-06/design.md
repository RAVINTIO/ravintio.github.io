# Design - 0000024-explainer-six-tools

## Feature
- Problem: The explainer gives RAVINTIO Zero and RAVINTIO Framework about 60% of its words, so new readers see a coding agent rather than six tools with one purpose.
- Adoption mode: standard-iterative. Signal: `plan/_archive/` holds three prior runs and `src/` holds two components. Assumed as the only signal.
- Feature ID: 0000024-explainer-six-tools
- Version: `0.6.0`, a minor bump from `0.5.0`.
- Discovery: see `plan/_archive/0000024-explainer-six-tools-2026-11-06/discovery.md`.

## Product Layer
- User stories:
  - US-001: As a new reader, I read one page that explains all six tools and their shared purpose, so that I see RAVINTIO as more than a coding agent.
  - US-002: As a person who finds a page in search results, I read a summary of that page, so that I know whether to open it.
  - US-003: As a reader, I read sentences that name who acts, so that I know what each tool does.
- Acceptance criteria confirmed: 8
  - US-001 AC-1: The opening paragraph of `what-is-ravintio.md` names visibility and governance over agentic software development.
  - US-001 AC-2: The page has one entry for each of the six tools. The longest entry has at most 1.5 times the words of the shortest.
  - US-001 AC-3: The "Why RAVINTIO?" section names no single tool.
  - US-001 AC-4: The homepage subtitle names the shared purpose and no single tool.
  - US-002 AC-1: Each doc page has one `<meta name="description">`, built from a `description` field in `docs.manifest.json`.
  - US-002 AC-2: Each description is unique and runs 50 to 160 characters.
  - US-003 AC-1: The nine sentences that backlog 0000021 lists use active voice.
  - US-003 AC-2: `style.test.mjs` fails a page that holds "is", "are", "was", or "were" before a participle. An allowlist covers adjective uses such as "are merged".
- Constraints:
  - Four tools are in design. The pages state their aims with active hedges such as "aims to", and never claim a feature exists.
  - The explainer structure: shared purpose first, then "Why RAVINTIO?", then one entry per tool, then the three areas, shared principles, and independence, then "Where to go next".
  - `six-tools.md` changes only for active voice.
- Integrations: none.

## Architecture Layer
- Latency target: not applicable to a static site. Page weight stays under 500 KB.
- Availability target: unchanged, GitHub Pages.
- Scalability target: not applicable.
- Security: no authentication. The site and its data are public. No workflow permission changes.
- Data privacy: no regulated data.
- Observability: standard defaults. The Playwright report and the P3 quality report.
- Cost boundary: not constrained. GitHub Actions free tier.

## Engineering Layer
- Stack: TypeScript, Vite 7, `marked`, `mermaid` 12. Tests: `node --test` plus `@playwright/test` on Chromium. CI: GitHub Actions. Build target: local.
- Components:
  - `site-content` (existing): owns the page Markdown. It takes the explainer rewrite and the active-voice fixes.
  - `web-app` (existing): owns the homepage, `docs.manifest.json`, `build-docs.js`, and the tests. It takes the subtitle, the descriptions, and the new checks.
- Data ownership:
  - `src/site-content/pages/*.md`: `site-content`.
  - `src/web-app/index.html`, `docs.manifest.json`, `scripts/`, and `tests/`: `web-app`.
- Dependency order: US-003 AC-2 adds the voice check after the page fixes, or the check lands RED first and the fixes turn it GREEN. US-001 and US-002 are independent. US-001 and US-003 both edit `what-is-ravintio.md` and `six-tools.md`, so they run in sequence.
- Deployment: unchanged. `deploy.yml` publishes to GitHub Pages on a push to `main`.
- API versioning: not applicable.

## Scope
- In:
  - Rewrite `what-is-ravintio.md` around the shared purpose with equal entries for the six tools.
  - Change the homepage subtitle to name the shared purpose.
  - Add a `description` per page to `docs.manifest.json` and write it into each page `<head>`.
  - Rewrite passive sentences on every page that the new check flags, including the "is designed to" hedges.
  - Add the passive-voice check with an allowlist to `style.test.mjs`.
- Out:
  - Rebalancing `six-tools.md` content.
  - The header code link, which still points to the Zero repository.
  - Backlog 0000014, 0000015, 0000018, 0000019, 0000020, and 0000022.
- Deferred: nothing deferred.

## Assumptions
- The regex check finds passive voice with an allowlist small enough to maintain. Impact if wrong: false positives grow, and the human may drop AC-2 of US-003 through a mid-pipeline change.
- The homepage meta description stays as it is. Impact if wrong: AC-2 of US-002 also needs a homepage update.

## Risks
- The voice check flags adjective uses across many pages. Likelihood: medium. Impact: low. The allowlist absorbs them.
- The rewrite drifts into overclaiming in-design tools. Likelihood: low. Impact: medium. The constraint on hedges and the P3 review guard it.
- Equal-length entries read as padded for in-design tools. Likelihood: medium. Impact: low. The 1.5 ratio leaves room.

## Dependencies
- Upstream: none.
- Downstream: none.
- Approved dependencies: none.

## Active Skills
- `site-quality-review` (`ravintio-overrides/capability-skills/`), run in P3.

## Skill Map
| Requirement | Best-fit Skill | Rationale |
|-------------|----------------|-----------|
| US-001 - explainer rebalance | ravintio-implement | Content tests on word ratios and section text through the TDD loop |
| US-002 - meta descriptions | ravintio-implement | Manifest field, build change, and a test on the built pages |
| US-003 - active voice | ravintio-implement | Voice check goes RED on the current pages, then the rewrites turn it GREEN |

## Repo Instructions
### custom-002-push-and-raise-prs.md
You may fetch, pull, and push feature branches, and raise pull requests into `main` with `gh pr create`. Never merge a pull request into `main`, and never push to `main` directly. The human reviews and merges every pull request. Work on a `feat/` branch directly in the working directory. Don't use git worktrees. If a push or `gh` command fails, report the exact error and stop. Never retry with force.

### custom-003-site-quality-review.md
In P3 of every run, after the Playwright suite passes, load and run the `site-quality-review` capability skill. The skill writes `plan/current/site-quality-report.md`, fixes fix-now findings in the run, and files the rest to `plan/backlog/`.

## Confirmation
Human confirmed this design before proceeding: yes // Date and Time confirmed: 06 Nov 2026 @ 04:34 p.m. GMT
