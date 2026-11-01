---
title: "Feature Brief - Site regression and quality"
summary: "The business case, scope, and product requirements for the feature."
status: "approved"
version: "0.1.0"
---
# Feature Brief - Site regression and quality

**Feature ID:** 0000016-site-regression-and-quality

## Business Goal

The docs site has no browser tests and runs no tests in CI. Breakage reaches readers before anyone sees it. This run adds a Playwright regression suite, runs both suites on each pull request, and adds a quality review to every run. It also fixes the white flash that dark-theme readers see on each page load.

## Features

The stories and the 17 acceptance criteria are in `plan/current/design.md`. This table records where each item came from.

| Feature | Source | Notes |
|---------|--------|-------|
| No white flash on page load | Backlog 0000013 | The screen flashes white when a page loads. The likely cause is that `src/web-app/src/main.ts` sets `data-theme` in a deferred module script, so the light palette in `style.css` paints first. Suggested fix: set the theme in an inline script at the top of `<head>` in `build-docs.js` and `index.html`. Confirm the cause in a browser first, in both themes, on a doc page and on the homepage. |
| Playwright regression and site quality review | Human request | Add Playwright MCP and a Playwright regression suite for the website. Each run, analyse the site's quality. Fix what needs fixing now, and file the rest as backlog suggestions. |

## Deferred

- Framework user docs: split out to keep the run within the 14-point budget. Framework is under major rework. Re-filed in `plan/backlog/`.

## Scenario Paths

The four paths are in the build log under `Scope Lock`. The human accepted each draft.
