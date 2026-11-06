---
title: "Feature Brief - pending"
summary: "The business case, scope, and product requirements for the feature."
status: "draft"
version: "0.1.0"
---
# Feature Brief - pending

**Feature ID:** pending

## Business Goal

The explainer gives RAVINTIO Zero and RAVINTIO Framework more weight than the other four tools. Readers should instead get a high-level view of all six tools. They should also see the shared purpose: visibility and governance over agentic software development.

## Pulled-in backlog entries

### 0000023 - Rebalance the explainer to all six tools

The human's brief, verbatim: "Next release needs to be content to look at how much of the explainer is focused on Zero and Framework. That explainer needs to be a 10000ft view of all six tools and the shared purpose of visibility and governance over the Agentic software development landscape."

Pages in scope to assess:
- `src/site-content/pages/what-is-ravintio.md`, the explainer.
- `src/site-content/pages/six-tools.md`, the tool overview.
- `src/web-app/index.html`, whose subtitle points readers to RAVINTIO Zero.

Suggested action: measure how much of each page covers Zero and Framework against the other four tools. Rewrite the explainer as a high-level view of all six tools and their shared purpose.

### 0000017 - Add meta descriptions to doc pages

Area: navigation and metadata. Page: all ten doc pages. None of them has a `<meta name="description">`. Only the homepage has one. Search results and link previews then show arbitrary page text. Evidence: the review read `document.querySelector('meta[name=description]')` on each page in `plan/_archive/0000016-site-regression-and-quality-2026-11-01/site-quality-report.md` (finding N-001).

Suggested action: Give each page a description. One option is a `description` field per page in `docs.manifest.json`, which the `build-docs.js` template writes into `<head>`. Add a regression test that every page has a unique description.

## Features

Coaching fills this section.

## Acceptance Criteria

Coaching fills this section.
