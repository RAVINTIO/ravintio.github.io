# Design - 0000009-bug-fixes

## Feature
- Problem: the 0.4.0 site explains RAVINTIO from the inside out, has a failing first-run command, buries mobile content under ten nav links, and carries 16 npm audit advisories. The target user is a developer with a coding agent deciding whether to adopt RAVINTIO Zero.
- Adoption mode: standard-iterative (signal: `plan/_archive/` holds 4 runs beside `src/`)
- Feature ID: 0000009-bug-fixes
- Version: 0.4.1 (patch, confirmed)
- Discovery: see `plan/current/discovery.md`

## Product Layer
- User stories:
  - US-001: As a developer evaluating agent tooling, I read why I should use RAVINTIO before any detail about the name or the tools, so that I can judge its value quickly.
  - US-002: As a developer, I read how Zero keeps solutions simple and avoids needless complexity, so that I trust it won't leave me a maintenance burden.
  - US-003: As a developer evaluating Zero, I read why to use Zero and when it fits before its glossary, so that the page helps me decide.
  - US-004: As a developer adopting Zero, I follow the install and first-run pages without a failing command or confusing wording, so that my first run works.
  - US-005: As a reader on a phone, I see the page content first, with the page list collapsed, so that I don't scroll past ten links to start reading.
  - US-006: As the site maintainer, I build the site with no known advisories in its dependencies, so that the build chain stays safe.
- Acceptance criteria confirmed: 13
  - US-001 AC-1: "Why use RAVINTIO" holds the ten agreed items. No "The name" heading, letter table, or block-capitals sentence.
  - US-001 AC-2: "Shared design principles" holds human authority, blameless learning, and assessment that challenges the work, only.
  - US-002 AC-1: `zero-overview.md` has "How Zero keeps solutions simple" covering discovery, plan, implement, and standards.
  - US-002 AC-2: `pipeline.md` P2 states that each improvement cycle asks whether a simpler solution meets the same tests.
  - US-003 AC-1: the first section of `zero-overview.md` is "Why use Zero", and "Terms" is last.
  - US-003 AC-2: "When Zero fits" replaces "Limits of Zero", with no benchmark line.
  - US-004 AC-1: the first-run step 2 commands succeed on a fresh setup.
  - US-004 AC-2: install, first-run, six-tools, and homepage wording match review findings 5 to 8.
  - US-005 AC-1: at 360 by 740 px the page list is closed by default and the first heading is in the first viewport. (browser check)
  - US-005 AC-2: the toggle works by keyboard and exposes its open state. (browser check)
  - US-005 AC-3: at 1280 px the sidebar is unchanged.
  - US-006 AC-1: `npm audit` reports 0 advisories.
  - US-006 AC-2: `npm run build` and `npm test` pass.
- Confirmed copy (agreed text in the P0 coaching log of `build-log.md`):
  - Copy bug 1: new opening paragraph and the "Why use RAVINTIO" list on `what-is-ravintio.md`. Letter table and capitals line removed. Principles trimmed.
  - Copy bug 2: the simplicity bullet after "Constraints hold", the zero-overview simplicity section, and the pipeline P2 sentence.
  - Review findings 1 to 8: `mkdir -p plan/current` in first-run step 2. Zero overview leads with "Why use Zero", glossary last. "When Zero fits". Install drops "The pack states no minimum version". First-run "What you have now" adds what the outputs give you. Six-tools headings become "What it does" and "What it works alongside". Hero subtitle becomes "Coding agents that build to your design and standards, and prove the result."
- Constraints:
  - Prose follows the Google developer documentation style variant in the user's style guide.
  - Every claim about Zero matches the installed `ravintio-zero/` pack.
  - No page names the earlier brand or quotes the private strategy.
- Integrations: GitHub Pages through `deploy.yml`.

## Architecture Layer
- Latency target: not applicable (static site).
- Availability target: GitHub Pages default.
- Scalability target: not applicable.
- Mobile: no horizontal scroll at 360 px. First heading in the first viewport at 360 by 740 px.
- Accessibility: WCAG 2.2 AA. The disclosure is a native `<details>` and `<summary>`, so keyboard use and state come from the browser.
- Security: no authentication. Public static content. Data classification: public. `npm audit` reports 0 advisories.
- Data privacy: no regulated data. No reader data collected or stored.
- Observability: standard defaults.
- Cost boundary: not constrained.

## Engineering Layer
- Stack: Markdown content, Node 24 build scripts, Vite 7, `marked`, `mermaid`, TypeScript, `node --test`, GitHub Actions and GitHub Pages. Build target: local.
- Components:
  - `site-content` (existing): owns the ten pages. Changes in US-001 to US-004.
  - `web-app` (existing): builds the site. Changes in US-004 (homepage), US-005 (nav), and US-006 (dependencies).
- Mobile nav approach: `build-docs.js` wraps the section nav in `<details open>` with a `<summary>` naming the current page. Below 900 px, `main.ts` closes it on load. Above 900 px, CSS hides the summary, so the sidebar looks as it does now. Without JavaScript, the list stays open.
- Dependency order: none between stories. Each touches separate files, except US-001 and US-002, which both edit `what-is-ravintio.md`.
- Data ownership: `site-content` owns `src/site-content/pages/*.md`. `web-app` reads them at build time.
- Deployment: merge to `main` triggers `deploy.yml`, which publishes to `https://ravintio.github.io`.
- API versioning: not applicable.

## Scope
- In: US-001 to US-006 as above.
- Out: Framework docs (backlog `0000006`), Zero pack changes, new pages, nav order changes.
- Deferred: nothing deferred.

## Assumptions
- `npm audit fix` within current majors changes no site behaviour - impact if wrong: a build or rendering regression, caught by `npm test` and the P3 browser check.

## Risks
- The audit fix changes `mermaid` rendering. Likelihood: low. Impact: medium. Mitigation: P3 browser check of the pipeline diagram page.
- New copy breaks the sentence-length or blocklist test. Likelihood: medium. Impact: low. Mitigation: `style.test.mjs` runs in P2.
- The closed disclosure hides navigation from readers who miss the toggle. Likelihood: low. Impact: low. Mitigation: the summary names the current page and shows a disclosure marker.

## Dependencies
- Upstream: `ravintio-zero/` pack (claims about Zero).
- Downstream: none.
- Approved dependencies: none new. Patch and minor updates of existing `vite`, `mermaid`, and their transitive dependencies through `npm audit fix`, within current majors.

## Active Skills
None

## Skill Map
| Requirement | Best-fit Skill | Rationale |
|-------------|----------------|-----------|
| REQ-001 - why-use-ravintio | ravintio-implement | Content test drives the page change |
| REQ-002 - simplicity-guidance | ravintio-implement | Content test drives two page changes |
| REQ-003 - zero-overview-reframe | ravintio-implement | Section-order test drives the restructure |
| REQ-004 - copy-fixes | ravintio-implement | Content tests drive four small fixes |
| REQ-005 - mobile-section-nav | ravintio-implement | Built-HTML test plus P3 browser check |
| REQ-006 - dependency-advisories | ravintio-implement | Audit, build, and test results |

## Repo Instructions
### custom-002-push-and-raise-prs.md
You may fetch, pull, and push feature branches, and raise pull requests into `main` with `gh pr create`. Never merge a pull request into `main`, and never push to `main` directly. The human reviews and merges every pull request. Work on a `feat/` branch directly in the working directory. Don't use git worktrees. If a push or `gh` command fails, report the exact error and stop. Never retry with force.

## Confirmation
Human confirmed this design before proceeding: pending
