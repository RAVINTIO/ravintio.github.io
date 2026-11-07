---
title: "Feature Brief - explainer-six-tools"
summary: "The business case, scope, and product requirements for the feature."
status: "approved"
version: "0.1.0"
---
# Feature Brief - explainer-six-tools

**Feature ID:** 0000024-explainer-six-tools

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

### 0000021 - Rewrite passive sentences on three pages

Area: content. Pages: `six-tools.md`, `project-operations.md`, and `skills.md`. These sentences break the repo's active-voice rule:
- `six-tools.md` lines 21, 24, 83, and 85: "is designed to".
- `project-operations.md` line 3: "how commit messages are checked".
- `project-operations.md` line 11: "if code is staged without documentation".
- `project-operations.md` line 133: "The pack is shared with the team".
- `skills.md` line 26: "after the design is confirmed".
Evidence: a scan of `src/site-content/pages/` for "is" or "are" plus a participle (finding C-001). The "are merged" and "you are satisfied" hits in `first-run.md` are adjectives, not passive voice.

Suggested action: Rewrite each sentence with a named actor, for example "Accept checks a change from..." and "the hook checks commit messages". Consider a passive-voice check in `style.test.mjs`.

## Features and acceptance criteria

See `plan/_archive/0000024-explainer-six-tools-2026-11-06/design.md`, Product Layer: US-001 to US-003 with eight criteria.
