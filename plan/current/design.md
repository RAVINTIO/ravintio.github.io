# Design - 0000005-ravintio-docs-rewrite

## Feature
- Problem: developers who use coding agents have no accurate site that explains RAVINTIO or teaches them to adopt RAVINTIO Zero. The current site carries an earlier brand and obsolete content.
- Adoption mode: standard-iterative (assumed; signal: `plan/_archive/` holds 3 runs beside `src/`)
- Feature ID: 0000005-ravintio-docs-rewrite
- Version: 0.4.0 (minor bump from 0.3.0, confirmed by the human)
- Discovery: see `plan/current/discovery.md`

## Product Layer
- Primary reader: a developer who uses a coding agent and is deciding whether to adopt Zero. Path: understand RAVINTIO, install Zero, run a first feature.
- User stories:
  - US-001: As a developer evaluating agent tooling, I read what RAVINTIO is and what each of its six tools does, so that I can pick the tool that fits my problem.
  - US-002: As a developer adopting Zero, I follow the install and first-run guides, so that I can take a first feature to a pull request using only the site.
  - US-003: As a Zero user, I look up a skill, standard, or template, so that I can check what the pack provides.
  - US-004: As a reader, I find the site under the RAVINTIO name and logo with no trace of the earlier brand, so that the product reads as one thing.
- Page structure (confirmed):

  | Section | Page |
  |---------|------|
  | RAVINTIO | 1. What is RAVINTIO |
  | RAVINTIO | 2. The six tools |
  | Zero | 3. Zero overview |
  | Zero | 4. Install Zero |
  | Zero | 5. Your first run |
  | Zero | 6. The pipeline |
  | Zero | 7. Project operations |
  | Reference | 8. Skills |
  | Reference | 9. Standards |
  | Reference | 10. Templates |

- Acceptance criteria confirmed: 7
  1. `npm run build` passes, and the nav shows the ten pages in order under three labelled sections. (automated)
  2. "Planifest", in any case, appears nowhere in source content, the built site, or folder and file names, except `plan/_archive/`, `plan/changelog/`, and git history. (automated)
  3. Every brand mention reads `RAVINTIO` in block capitals. Product names take the form "RAVINTIO Zero". (automated)
  4. The site holds none of the strategy's private sections, and each tool carries its confirmed status label. (human checklist)
  5. Every skill, standard, and template on the reference pages exists in `ravintio-zero/`, and every pack item appears on its page. (automated)
  6. Every internal link and anchor resolves. (automated)
  7. Every sentence stays under 25 words and avoids the style-guide blocklist. (automated)
- Constraints:
  - All content is new. No text comes from the old pages.
  - Sources: the public parts of the private RAVINTIO strategy, and the current `ravintio-zero/` pack and Zero repo README.
  - The private strategy is never committed or quoted. Excluded sections: implementation sequence, open design questions, threat model, proposed repo names.
  - No page names or explains the earlier brand.
  - Status labels: Zero and Framework "Available". Accept, Qualify, and Insight "In design". Unbound "In design, experimental research only". Purpose and boundaries only for "In design" tools. No dates, sequences, or "coming soon" wording.
  - Prose follows the Google developer documentation style variant in the user's style guide.
- Integrations: GitHub Pages through the existing `deploy.yml` workflow.

## Architecture Layer
- Latency target: not applicable (static site). Page weight under 300 KB on first load, excluding `mermaid`, which loads only on pages with diagrams.
- Availability target: GitHub Pages default. Not separately constrained.
- Scalability target: not applicable.
- Accessibility: WCAG 2.2 level AA, including teal logo colour contrast, alt text, and keyboard navigation.
- Mobile: no horizontal scroll at 360 pixels wide.
- Build: `npm run build` under 60 seconds in CI.
- Security: no authentication. Public static content. Data classification: public. The private strategy is classified confidential and stays outside the repo.
- Data privacy: no regulated data. No reader data collected.
- Observability: standard defaults (GitHub Actions build and deploy logs).
- Cost boundary: not constrained (GitHub Pages free tier).

## Engineering Layer
- Stack: Markdown content, Node 24 build scripts, Vite 7, `marked`, `mermaid`, TypeScript. Tests use `node --test`. CI and hosting are GitHub Actions and GitHub Pages. Build target: static.
- Components:
  - `site-content` (new, `src/site-content/`): owns the ten Markdown pages in `pages/` and its component docs in `docs/`.
  - `web-app` (existing, `src/web-app/`): builds the site, owns the nav manifest with section grouping, styling, the logo, and favicons.
- Dependency order: `site-content` first, then `web-app` changes that read it.
- Data ownership: `site-content` owns `src/site-content/pages/*.md`. `web-app` owns `docs.manifest.json`, `scripts/`, `public/`, and `src/`. `web-app` reads pages at build time and never writes them.
- Deployment: push to `main` triggers `deploy.yml`, which builds `src/web-app` and publishes `dist/` to Pages. After the human renames the repo, the address is `ravintio.github.io/ravintio-docs`.
- API versioning: not applicable.

## Scope
- In:
  - The ten new pages and the `site-content` component.
  - Delete `planifest-docs/`, `src/planifest-docs/`, and the three obsolete pages.
  - Remove the earlier brand from the site code, generated pages, repo docs, `plan/README.md`, and `plan/feature-structure.md`.
  - Nav manifest with three labelled sections, and an updated sitemap.
  - The supplied logo (`graphics/ravintio-logo.png`) in the header beside a "RAVINTIO" wordmark, a resized page asset, and a favicon set built from it. Delete the old logo and favicon files.
  - Replace `refresh-planifest-framework-dir.ps1` with a `ravintio-zero` version.
  - A brand guard test with a path allowlist, plus the automated tests for criteria 1, 3, 5, 6, and 7.
- Out:
  - Full RAVINTIO Framework docs (backlog `0000006`).
  - Renaming the GitHub repo (the human's action).
  - A custom domain.
  - Redirects from old URLs.
  - README links in the `ravintio-zero` repo.
- Deferred: nothing deferred.

## Assumptions
- The human renames the GitHub repo to `ravintio-docs` before the first deploy - impact if wrong: the site deploys to the old address and pushes to the new remote URL fail.
- The `ravintio-zero/` pack installed in this repo matches the published Zero release - impact if wrong: reference pages describe a different version than readers install.
- Framework is publicly available - impact if wrong: its "Available" label misleads readers.
- The supplied logo PNG works on light and dark backgrounds - impact if wrong: the header needs a variant.

## Risks
- Private strategy content leaks onto the site. Likelihood: medium. Impact: high. Mitigation: criterion 4 checklist review at P3.
- Pack drift makes reference pages stale. Likelihood: high. Impact: medium. Mitigation: criterion 5 test fails the build.
- The teal logo colour fails AA contrast as a text or link colour. Likelihood: medium. Impact: medium. Mitigation: use a darker shade for text and check contrast at P3.
- Old inbound links break. Likelihood: high. Impact: low. Accepted, with no redirects.
- The sentence-length test flags valid content such as tables or code. Likelihood: medium. Impact: low. Mitigation: the test checks prose only.

## Dependencies
- Upstream: `ravintio-zero/` pack (skills, standards, templates), Zero repo README, the private strategy (outside the repo).
- Downstream: none.
- Approved dependencies: none. Image resizing uses macOS `sips` or an equivalent run once, with the outputs committed.

## Active Skills
None

## Skill Map
| Requirement | Best-fit Skill | Rationale |
|-------------|----------------|-----------|
| US-001 - ravintio-overview | ravintio-implement | Content pages land with their tests through the TDD loop |
| US-002 - zero-adoption-guide | ravintio-implement | Pages and link and style tests land together |
| US-003 - zero-reference | ravintio-implement | The reference-match test drives the page content |
| US-004 - brand-and-structure | ravintio-implement | The brand guard and nav tests drive the rename and manifest change |

## Repo Instructions
### custom-001-local-git-only.md
Don't fetch, pull, push or otherwise attempt to use remote git commands. Commit changes to a local feature branch. The human on the loop confirms it is up to date at the start of a plan, pushes the code, and creates pull requests. Don't use git worktrees. Work on a `feat/` branch directly in the working directory.

## Confirmation
Human confirmed this design before proceeding: yes // Date and Time confirmed: 29 Oct 2026 @ 08:30 p.m. UTC
