---
title: "Site quality report: 0000024-explainer-six-tools"
summary: "Findings from the P3 site quality review, sorted into fix-now and backlog."
---
# Site quality report: 0000024-explainer-six-tools

| Field | Value |
|-------|-------|
| Feature id | 0000024-explainer-six-tools |
| Date | 2026-11-06 |
| Pages reviewed | 12: the homepage, the ten manifest pages, and the sitemap |
| Preview URL | http://localhost:4173 |

## Summary

| Area | Fix-now | Backlog |
|------|---------|---------|
| Accessibility | 0 | 1 (existing 0000019) |
| Layout | 0 | 1 (existing 0000020) |
| Content | 2 (fixed) | 1 |
| Performance | 0 | 0 |
| Navigation and metadata | 0 | 2 (existing 0000018, new 0000025) |

## Accessibility

**Target:** WCAG 2.2 AA, read from the accessibility tree.

| ID | Page | Finding | Evidence | Sorting | Action |
|----|------|---------|----------|---------|--------|
| A-001 | Homepage | The homepage still has no `<main>` landmark. | `document.querySelectorAll('main').length` returned 0 on `/`. Every doc page returned 1. No heading skips, missing alt text, or unnamed links on any page. | backlog | Evidence added to 0000019 |

## Layout

**Target:** no overlap, clipping, or sideways scroll at 390 px and 1280 px, in both themes.

| ID | Page | Finding | Evidence | Sorting | Action |
|----|------|---------|----------|---------|--------|
| L-001 | All doc pages at 390 px | The text column stays narrow on phones. | Screenshot of the explainer at 390 px in the dark theme. No page scrolls sideways at 390 px. The homepage hero and the explainer at 1280 px in the light theme show no overlap or clipping. | backlog | Evidence added to 0000020 |

## Content

**Target:** the repo's writing style, and facts that match the installed pack.

| ID | Page | Finding | Evidence | Sorting | Action |
|----|------|---------|----------|---------|--------|
| C-001 | Homepage | The meta description read "autonomous software engineering… Start with RAVINTIO Zero", which contradicted the new subtitle. | `meta[name=description]` content on `/`. This run caused it. | fix-now (S) | Fixed in `5d16a06`, with a new test in `explainer.test.mjs` |
| C-002 | `what-is-ravintio.md` | The Insight entry repeated "aims to" three times. | Explainer line 37. This run caused it. | fix-now (S) | Fixed in `5d16a06` |
| C-003 | `project-operations.md` | A table cell reads "The CI gate only works once committed." It hides the actor. | Found by the U3 track. The voice check cannot catch it because it has no be-verb. | backlog | 0000026 |

## Performance

**Target:** page weight under 500 KB, and LCP under 2.5 s on the preview.

| ID | Page | Finding | Evidence | Sorting | Action |
|----|------|---------|----------|---------|--------|
| none | All | No finding. The homepage weighs 83 KB. The explainer weighs 14 KB with an LCP of 60 ms. | `transferSize` and `encodedBodySize` sums, and a buffered LCP observer | none | none |

## Navigation and metadata

**Target:** a unique `<title>` and meta description on each page, a working 404, and a favicon.

| ID | Page | Finding | Evidence | Sorting | Action |
|----|------|---------|----------|---------|--------|
| N-001 | Any missing URL | The site still has no custom 404 page. | Unchanged since run 0000016. All 12 pages have a unique title and exactly one meta description. | backlog | Evidence added to 0000018 |
| N-002 | Every page | The header code link points to the Zero repository only. | `a.code-icon-link` with the label "RAVINTIO Zero on GitHub". The story map recorded it as an out-of-scope gap. | backlog | 0000025 |
