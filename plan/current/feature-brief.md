---
title: "Feature Brief - pending"
summary: "The business case, scope, and product requirements for the feature."
status: "draft"
version: "0.1.0"
---
# Feature Brief - pending

**Feature ID:** pending

## Business Goal

Pending coaching.

## Features

Stories and criteria are pending coaching.

| Feature | Source | Notes |
|---------|--------|-------|
| No white flash on page load | Backlog 0000013 | The screen flashes white when a page loads. The likely cause is that `src/web-app/src/main.ts` sets `data-theme` in a deferred module script, so the light palette in `style.css` paints first. Suggested fix: set the theme in an inline script at the top of `<head>` in `build-docs.js` and `index.html`. Confirm the cause in a browser first, in both themes, on a doc page and on the homepage. |
| Playwright regression and site quality review | Human request | Add Playwright MCP and a Playwright regression suite for the website. Each run, analyse the site's quality. Fix what needs fixing now, and file the rest as backlog suggestions. |

## Deferred

- Framework user docs: split out to keep the run within the 14-point budget. Framework is under major rework. Re-filed in `plan/backlog/`.
