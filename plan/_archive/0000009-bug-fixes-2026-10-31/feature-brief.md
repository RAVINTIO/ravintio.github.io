---
title: "Feature Brief - Bug fixes for copy, mobile nav, and dependencies"
summary: "The business case, scope, and product requirements for the feature."
status: "approved"
version: "0.4.1"
---
# Feature Brief - Bug fixes for copy, mobile nav, and dependencies

**Feature ID:** 0000009-bug-fixes

## Business Goal

The 0.4.0 site explains RAVINTIO from the inside out. It opens with the name and the internals, not with why a developer should use it. This run reframes the copy around the developer's reasons to adopt RAVINTIO and Zero. It also fixes a broken first-run step, collapses the mobile section nav, and clears the npm audit advisories.

## Features

| Feature | User Stories | Priority | Wave |
|---------|-------------|----------|------|
| Why use RAVINTIO | US-001: As a developer evaluating agent tooling, I read why I should use RAVINTIO before any detail about the name or the tools, so that I can judge its value quickly. | must-have | 1 |
| Simplicity guidance | US-002: As a developer, I read how Zero keeps solutions simple and avoids needless complexity, so that I trust it won't leave me a maintenance burden. | must-have | 1 |
| Zero overview reframe | US-003: As a developer evaluating Zero, I read why to use Zero and when it fits before its glossary, so that the page helps me decide. | must-have | 1 |
| Copy fixes | US-004: As a developer adopting Zero, I follow the install and first-run pages without a failing command or confusing wording, so that my first run works. | must-have | 1 |
| Mobile section nav | US-005: As a reader on a phone, I see the page content first, with the page list collapsed, so that I don't scroll past ten links to start reading. | must-have | 1 |
| Dependency advisories | US-006: As the site maintainer, I build the site with no known advisories in its dependencies, so that the build chain stays safe. | must-have | 1 |

## Waves

| Wave | Features Included | Ships When |
|------|-------------------|------------|
| 1 | All six | One run, 9 of 14 points |

## Target Architecture

### Components

| Component | Type | New or Existing | Responsibility |
|-----------|------|-----------------|---------------|
| site-content | component-pack | existing | Owns the ten Markdown pages |
| web-app | microfrontend | existing | Builds the static site, nav, styles, and homepage |

### Data Ownership

| Data Store | Owner Component | Shared With |
|------------|----------------|-------------|
| `src/site-content/pages/*.md` | site-content | web-app (read only, at build time) |

### Integration Points

| From | To | Method | Contract |
|------|-----|--------|----------|
| web-app | site-content | file read at build | `build-docs.js` reads pages named in `docs.manifest.json` |

## Stack

| Concern | Decision |
|---------|----------|
| Language | TypeScript, JavaScript, Markdown |
| Runtime | Node 24 |
| Framework | Vite 7 |
| Frontend | static HTML, no framework |
| Database | none |
| ORM | none |
| Testing | `node --test` |
| IaC | none |
| Cloud | GitHub Pages |
| Compute | none |
| CI | GitHub Actions |
| Build target | local |

## Scope Boundaries

### In Scope

- The confirmed copy changes from copy bugs 1 and 2 and site review findings 1 to 8, in the P0 coaching log.
- A collapsed page-list disclosure below 900 px.
- `npm audit fix` within the current majors.

### Out of Scope

- Full RAVINTIO Framework docs (backlog `0000006`).
- Changes to the Zero pack.
- New pages or changes to the nav order.

### Deferred

- Nothing deferred.

## Non-Functional Requirements

| NFR | Target | Measurement |
|-----|--------|-------------|
| Mobile layout | No horizontal scroll at 360 px. The first page heading sits in the first viewport at 360 by 740 px. | Browser check |
| Accessibility | WCAG 2.2 AA. The disclosure works by keyboard and states its open state. | Browser check |
| Prose | Every sentence under 25 words, no blocklist terms | `style.test.mjs` |
| Security | `npm audit` reports 0 advisories | `npm audit` |

## Constraints and Assumptions

### Constraints

- New copy follows the Google developer documentation style variant in the user's style guide.
- Every claim about Zero matches the installed `ravintio-zero/` pack.
- No page names the earlier brand or quotes the private strategy.

### Assumptions

- `npm audit fix` within the current majors changes no build output beyond the dependency code.
