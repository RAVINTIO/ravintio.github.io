# Design - 0000027-site-quality-fixes

## Feature
- Problem: Seven findings from the last two site quality reviews stay open, and no automated accessibility check guards the site.
- Adoption mode: standard-iterative. Signal: `plan/_archive/` holds seven prior runs and `src/` holds two components. Assumed as the only signal.
- Feature ID: 0000027-site-quality-fixes
- Version: `0.7.0`, a minor bump from `0.6.0`.
- Discovery: see `plan/current/discovery.md`.

## Product Layer
- User stories:
  - US-001: As a maintainer, I run an axe-core scan on every page in both themes, so that CI catches accessibility rules a manual review misses.
  - US-002: As a reader who follows a broken link, I see a site page with links back to the docs, so that I can find what I wanted.
  - US-003: As a screen reader user, I jump to the homepage main content by landmark, so that I skip the header as I can on doc pages.
  - US-004: As a reader on a phone, I read a text column that uses most of the screen, so that lines don't wrap after five words.
  - US-005: As a maintainer, I run CI actions pinned by commit SHA, so that a moved tag can't change the code CI runs.
  - US-006: As a reader, I follow the header and footer code links to the RAVINTIO organisation, so that I see all six tools, not only Zero.
  - US-007: As a reader, I read a project operations table cell that names who acts, so that I know who commits the CI gate.
- Acceptance criteria confirmed: 14
  - US-001 AC-1: The Playwright suite runs an axe scan with the WCAG 2.2 AA tags on the homepage, the sitemap, the 404 page, and every manifest page, in light and dark themes.
  - US-001 AC-2: A serious or critical violation fails the suite.
  - US-001 AC-3: The suite writes moderate and minor violations to a JSON report that the P3 quality review reads.
  - US-002 AC-1: The build writes `dist/404.html` with the site header, a short message, and links to the homepage and the sitemap.
  - US-002 AC-2: The 404 page loads its stylesheet and script when served at a nested missing path such as `/docs/missing/page.html`.
  - US-003 AC-1: The homepage wraps its content below the header in one `<main id="content">`, and the skip link still targets `#content`.
  - US-003 AC-2: The page health suite fails any page without exactly one `<main>`.
  - US-004 AC-1: At a 390 px viewport, `main p` on every doc page is at least 330 px wide.
  - US-004 AC-2: No page scrolls sideways at 390 px.
  - US-005 AC-1: Every `uses:` line in `site-tests.yml` and `deploy.yml` holds a 40-character SHA with the tag in a comment.
  - US-005 AC-2: `site-tests-workflow.test.mjs` fails a `uses:` line in those two files without a full SHA.
  - US-006 AC-1: The header and footer code links on the homepage and every doc page point to `https://github.com/RAVINTIO`.
  - US-006 AC-2: The header link's `aria-label` and `title` read "RAVINTIO on GitHub".
  - US-007 AC-1: The `ravintio.yml` row in `project-operations.md` names the actor, for example "The CI gate works only after you commit it."
- Constraints:
  - Keep the declared stack. `@axe-core/playwright` is the one new dev dependency, pinned to an exact version.
  - `ravintio.yml` stays as `setup.sh` writes it.
  - In-body Zero repo links in `six-tools.md` and `install-zero.md` stay.
- Integrations: none.

## Architecture Layer
- Latency target: not applicable to a static site. Page weight stays under 500 KB.
- Availability target: unchanged, GitHub Pages.
- Scalability target: not applicable.
- Security: no authentication. The site and its data are public. Workflow permissions stay as they are. Action pins remove the moved-tag risk (S-001).
- Data privacy: no regulated data.
- Observability: standard defaults. The Playwright report, the axe JSON report, and the P3 quality report.
- Cost boundary: not constrained. GitHub Actions free tier.

## Engineering Layer
- Stack: TypeScript, Vite 7, `marked`, `mermaid` 12. Tests: `node --test`, `@playwright/test` on Chromium, and `@axe-core/playwright`. CI: GitHub Actions. Build target: local.
- Components:
  - `site-content` (existing): owns the page Markdown. It takes US-007.
  - `web-app` (existing): owns the shell, build, styles, workflows, and tests. It takes US-001 to US-006.
- Data ownership:
  - `src/site-content/pages/*.md`: `site-content`.
  - `src/web-app/` and `.github/workflows/site-tests.yml`, `deploy.yml`: `web-app`.
- Dependency order:
  - US-002 and US-003 add pages and markup that US-001 scans, so US-001 runs after them.
  - US-001 may surface violations. Each serious or critical one is fixed in US-001.
  - US-003 and US-006 both edit `index.html`, so they run in sequence.
  - US-004, US-005, and US-007 touch separate files and run in any order.
- 404 page: `src/web-app/404.html` is a Vite build input with `<base href="/">`, because GitHub Pages serves it at any depth and the site uses `base: './'`.
- Deployment: unchanged. `deploy.yml` publishes to GitHub Pages on a push to `main`.
- API versioning: not applicable.

## Scope
- In: US-001 to US-007 as the acceptance criteria above state.
- Out:
  - Pins in `ravintio.yml`, which the pack owns
  - In-body Zero repo links in `six-tools.md` and `install-zero.md`
  - Backlog 0000014
- Framing sweep (custom-004): the header link (`index.html:53`, `build-docs.js:118`) and footer link (`index.html:118`, `build-docs.js:136`) are in scope. The in-body links are out.
- Deferred: nothing deferred.

## Assumptions
- The site serves from the root of `ravintio.github.io`. Impact if wrong: `<base href="/">` breaks the 404 page assets, and US-002 AC-2 fails.
- The first axe scan surfaces few serious violations. Impact if wrong: US-001 grows past its 4 points, and the human may split fixes out through a mid-pipeline change.

## Risks
- The axe scan finds colour contrast violations in one theme. Likelihood: medium. Impact: medium. Token fixes in `style.css` resolve them.
- Mermaid diagrams render SVG that axe flags. Likelihood: medium. Impact: low. The scan waits for render, and a named rule exclusion needs human approval.
- A narrower card on phones crowds code blocks and tables. Likelihood: low. Impact: low. The sideways-scroll check guards it.

## Dependencies
- Upstream: none.
- Downstream: none.
- Approved dependencies: `@axe-core/playwright`, dev only.

## Active Skills
- `site-quality-review` (`ravintio-overrides/capability-skills/`), run in P3.

## Skill Map
| Requirement | Best-fit Skill | Rationale |
|-------------|----------------|-----------|
| US-001 - axe scans | ravintio-implement | Playwright spec goes RED on any serious violation, fixes turn it GREEN |
| US-002 - 404 page | ravintio-implement | Build input plus a page health check on a nested path |
| US-003 - homepage landmark | ravintio-implement | One-`<main>` check goes RED on the homepage first |
| US-004 - phone text width | ravintio-implement | Playwright width check at 390 px |
| US-005 - pinned actions | ravintio-implement | Workflow test goes RED on tag references |
| US-006 - organisation link | ravintio-implement | Link target and label checks on built pages |
| US-007 - table cell | ravintio-implement | Content check on the one cell |

## Repo Instructions
### custom-002-push-and-raise-prs.md
You may fetch, pull, and push feature branches, and raise pull requests into `main` with `gh pr create`. Never merge a pull request into `main`, and never push to `main` directly. The human reviews and merges every pull request. Work on a `feat/` branch directly in the working directory. Don't use git worktrees. If a push or `gh` command fails, report the exact error and stop. Never retry with force.

### custom-003-site-quality-review.md
In P3 of every run, after the Playwright suite passes, load and run the `site-quality-review` capability skill. The skill writes `plan/current/site-quality-report.md`, fixes fix-now findings in the run, and files the rest to `plan/backlog/`.

### custom-004-content-rewrites.md
If a run changes how a page frames RAVINTIO, list in P0 every place that repeats the old framing. Check meta descriptions, headers, subtitles, and link labels, and put each one in or out of scope at the design gate. After an improvement refactor rewrites prose, reread each changed paragraph as a whole before the commit.

## Confirmation
Human confirmed this design before proceeding: pending
