---
title: "Site quality report: {{feature-id}}"
summary: "Findings from the P3 site quality review, sorted into fix-now and backlog."
---
# Site quality report: {{feature-id}}

| Field | Value |
|-------|-------|
| Feature id | {{feature-id}} |
| Date | {{date}} |
| Pages reviewed | {{pages-reviewed}} |
| Preview URL | {{preview-url}} |

## Summary

| Area | Fix-now | Backlog |
|------|---------|---------|
| Accessibility | {{a11y-fix-now}} | {{a11y-backlog}} |
| Layout | {{layout-fix-now}} | {{layout-backlog}} |
| Content | {{content-fix-now}} | {{content-backlog}} |
| Performance | {{perf-fix-now}} | {{perf-backlog}} |
| Navigation and metadata | {{nav-fix-now}} | {{nav-backlog}} |

## Accessibility

**Target:** WCAG 2.2 AA, read from the accessibility tree.

| ID | Page | Finding | Evidence | Sorting | Action |
|----|------|---------|----------|---------|--------|
| {{id}} | {{page}} | {{finding}} | {{evidence}} | {{fix-now or backlog}} | {{fix unit or backlog id}} |

## Layout

**Target:** no overlap, clipping, or sideways scroll at 390 px and 1280 px, in both themes.

| ID | Page | Finding | Evidence | Sorting | Action |
|----|------|---------|----------|---------|--------|
| {{id}} | {{page}} | {{finding}} | {{evidence}} | {{fix-now or backlog}} | {{fix unit or backlog id}} |

## Content

**Target:** the repo's writing style, and facts that match the installed pack.

| ID | Page | Finding | Evidence | Sorting | Action |
|----|------|---------|----------|---------|--------|
| {{id}} | {{page}} | {{finding}} | {{evidence}} | {{fix-now or backlog}} | {{fix unit or backlog id}} |

## Performance

**Target:** page weight under 500 KB, and LCP under 2.5 s on the preview.

| ID | Page | Finding | Evidence | Sorting | Action |
|----|------|---------|----------|---------|--------|
| {{id}} | {{page}} | {{finding}} | {{evidence}} | {{fix-now or backlog}} | {{fix unit or backlog id}} |

## Navigation and metadata

**Target:** a unique `<title>` and meta description on each page, a working 404, and a favicon.

| ID | Page | Finding | Evidence | Sorting | Action |
|----|------|---------|----------|---------|--------|
| {{id}} | {{page}} | {{finding}} | {{evidence}} | {{fix-now or backlog}} | {{fix unit or backlog id}} |
