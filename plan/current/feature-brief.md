---
title: "Feature Brief - site-quality-fixes"
summary: "The business case, scope, and product requirements for the feature."
status: "draft"
version: "0.1.0"
---
# Feature Brief - site-quality-fixes

**Feature ID:** 0000027-site-quality-fixes

## Business Goal

The last two site quality reviews left seven open findings on the docs site. They cover accessibility, a missing 404 page, phone layout, CI supply-chain risk, and framing. This run closes all seven so readers on any device reach a consistent, accessible site. It also adds automated accessibility scans, so future regressions fail CI.

## Pulled-in backlog entries

The human pulled in these entries at P0 on 2026-11-07. Each section holds the entry's problem and suggested action.

### 0000015 - Add axe-core accessibility scans

#### Problem

The pending run adds a `site-quality-review` capability skill. Its accessibility check reads the accessibility tree through Playwright MCP and judges WCAG 2.2 AA by hand. A manual review misses rules that an automated engine checks on every element.

#### Suggested Action

Add `@axe-core/playwright` as a dev dependency. Run an axe scan on each manifest page in the Playwright regression suite, in both themes. Decide whether a serious or critical violation fails the suite, and feed the remaining violations into the quality review's triage.

### 0000018 - Add a custom 404 page

#### Problem

Area: navigation and metadata. Page: any missing URL. The site has no `404.html`. GitHub Pages then shows its own 404 page, with no site nav or link back to the docs. Evidence: a request for `/404.html` on the preview returned 404 (finding N-002).

#### Suggested Action

Add a `404.html` with the site header, a short message, and links to the homepage and the page list. Include it in the Vite build inputs and the page health suite.

### 0000019 - Add a main landmark to the homepage

#### Problem

Area: accessibility. Page: the homepage (`src/web-app/index.html`). It has no `<main>` element, while every doc page has one. Screen reader users can't jump to the main content by landmark. The skip link to `#content` still works, so WCAG 2.4.1 passes. Evidence: `document.querySelector('main')` returned null on `/` (finding A-001).

#### Suggested Action

Wrap the homepage content below the header in `<main id="content">`, and move the id from the hero header. Add a check to the page health suite that each page has one `<main>`.

### 0000020 - Widen the text column on phones

#### Problem

Area: layout. Page: all doc pages at 390 px. The page list card and the content card both add padding, so body text is 303 px wide in a 375 px viewport, starting 36 px from the edge. Lines wrap after five or six words. Evidence: `main p` measured at 303 px wide on `first-run.html` (finding L-001).

#### Suggested Action

Reduce the content card's side padding below 600 px, or drop the card border and background on phones, so the text column reaches about 340 px.

### 0000022 - Pin workflow actions by commit SHA

#### Problem

`.github/workflows/site-tests.yml` and `deploy.yml` reference `actions/checkout@v5`, `actions/setup-node@v5`, `actions/upload-artifact@v4`, and the Pages actions by tag. A moved tag would run different code in CI. Security report finding S-001, rated low.

#### Suggested Action

Pin each action by full commit SHA, with the tag in a comment. Add a check in `site-tests-workflow.test.mjs` that every `uses:` line holds a 40-character SHA.

### 0000025 - Point the header code link beyond Zero

#### Problem

Area: navigation. Pages: the homepage and every doc page. The header code icon links to the RAVINTIO Zero repository only, with the label "RAVINTIO Zero on GitHub". The site now presents six tools with one shared purpose, so the header still points readers to one tool. The run 0000024 story map recorded this step as a gap and `scope.md` put it out of scope.

#### Suggested Action

Point the link to the RAVINTIO GitHub organisation, or drop it in favour of links on each tool entry. Update the `aria-label` and `title` to match.

### 0000026 - Name the actor in a project operations table cell

#### Problem

Area: content. Page: `src/site-content/pages/project-operations.md`. A table cell reads "The CI gate only works once committed." It omits the actor and the be-verb, so it reads as passive, and the voice check in `style.test.mjs` cannot catch it. Evidence: the U3 TDD track in run 0000024 found it during the active-voice rewrite.

#### Suggested Action

Rewrite the cell with a named actor, for example "The CI gate works only after you commit it."

## Features

| Feature | User Stories | Priority | Wave |
|---------|-------------|----------|------|
| Accessibility scans | US-001: As a maintainer, I run an axe-core scan on every page in both themes, so that CI catches accessibility rules a manual review misses. | should-have | 1 |
| Custom 404 page | US-002: As a reader who follows a broken link, I see a site page with links back to the docs, so that I can find what I wanted. | should-have | 1 |
| Homepage landmark | US-003: As a screen reader user, I jump to the homepage main content by landmark, so that I skip the header as I can on doc pages. | should-have | 1 |
| Phone text width | US-004: As a reader on a phone, I read a text column that uses most of the screen, so that lines don't wrap after five words. | should-have | 1 |
| Pinned actions | US-005: As a maintainer, I run CI actions pinned by commit SHA, so that a moved tag can't change the code CI runs. | should-have | 1 |
| Organisation code link | US-006: As a reader, I follow the header and footer code links to the RAVINTIO organisation, so that I see all six tools, not only Zero. | should-have | 1 |
| Active-voice table cell | US-007: As a reader, I read a project operations table cell that names who acts, so that I know who commits the CI gate. | could-have | 1 |

## Waves

The seven stories are small and touch mostly separate files, so they ship as one wave. They total 13 of the 14-point budget.

| Wave | Features Included | Ships When |
|------|-------------------|------------|
| 1 | All seven | The Playwright suite, the Node tests, and the axe scans pass in CI |

## Target Architecture

### Components

| Component | Type | New or Existing | Responsibility |
|-----------|------|-----------------|---------------|
| `site-content` | component-pack | existing | Owns the page Markdown. Takes the table cell fix. |
| `web-app` | component-pack | existing | Owns the shell, build, styles, workflows, and tests. Takes the other six stories. |

### Data Ownership

| Data Store | Owner Component | Shared With |
|------------|----------------|-------------|
| `src/site-content/pages/*.md` | `site-content` | `web-app` (read only, at build) |
| `src/web-app/` and `.github/workflows/site-tests.yml`, `deploy.yml` | `web-app` | none |

### Integration Points

| From | To | Method | Contract |
|------|-----|--------|----------|
| `web-app` | `site-content` | file read at build | `build-docs.js` renders `pages/*.md` |

## Stack

| Concern | Decision |
|---------|----------|
| Language | TypeScript, JavaScript (ES modules) |
| Runtime | Node |
| Framework | Vite 7 |
| Frontend | static HTML, `marked`, `mermaid` 12 |
| Database | none |
| ORM | none |
| Testing | `node --test`, `@playwright/test` on Chromium, `@axe-core/playwright` (new dev dependency) |
| IaC | none |
| Cloud | GitHub Pages |
| Compute | none |
| CI | GitHub Actions |
| Build target | local |

## Scope Boundaries

### In Scope
- axe-core scans of every built page in light and dark themes in the Playwright suite
- A `404.html` with the site header, a message, and links to the homepage and sitemap
- A `<main id="content">` on the homepage and a one-`<main>` check on every page
- Narrower content card padding on phones
- SHA pins for every action in `site-tests.yml` and `deploy.yml`, with a test
- Header and footer code links that point to `https://github.com/RAVINTIO`
- The active-voice rewrite of one table cell in `project-operations.md`

### Out of Scope
- `.github/workflows/ravintio.yml`, which `ravintio-zero/setup.sh` writes. Pins there would not survive a setup refresh.
- In-body links to the Zero repo in `six-tools.md` and `install-zero.md`, which name Zero on purpose
- Backlog 0000014, Framework docs

### Deferred
- Nothing deferred.

## Non-Functional Requirements

| NFR | Target | Measurement |
|-----|--------|-------------|
| Accessibility | Zero serious or critical axe violations on every page in both themes | Playwright axe scan in CI |
| Page weight | Under 500 KB per page, unchanged | Built `dist/` sizes |
| Phone layout | Body text at least 330 px wide in a 390 px viewport, with no sideways scroll | Playwright layout check |
| Security | Every action in `site-tests.yml` and `deploy.yml` pinned by 40-character SHA | `site-tests-workflow.test.mjs` |

## Constraints and Assumptions

### Constraints
- Keep the declared stack. `@axe-core/playwright` is the one new dev dependency.
- GitHub Pages serves `404.html` from the domain root for any missing path at any depth.

### Assumptions
- The site serves from the root of `ravintio.github.io`. The 404 page uses `<base href="/">` so its assets resolve at any depth.
- The first axe scan surfaces few serious violations. Each one is fixed in this run.

## Scenario Paths

The Scope Lock Challenge in the build log holds the four paths.

## Acceptance Criteria

See `plan/current/design.md`.
