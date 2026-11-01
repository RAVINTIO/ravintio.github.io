---
title: "Site quality report: 0000016-site-regression-and-quality"
summary: "Findings from the P3 site quality review, sorted into fix-now and backlog."
---
# Site quality report: 0000016-site-regression-and-quality

| Field | Value |
|-------|-------|
| Feature id | 0000016-site-regression-and-quality |
| Date | 2026-11-01 |
| Pages reviewed | 11: the homepage and the ten manifest pages |
| Preview URL | `http://localhost:4173` |

Fix-now work came to 1 point, under the 2-point cap.

## Summary

| Area | Fix-now | Backlog |
|------|---------|---------|
| Accessibility | 0 | 1 |
| Layout | 0 | 1 |
| Content | 0 | 1 |
| Performance | 0 | 0 |
| Navigation and metadata | 1 | 2 |

## Accessibility

**Target:** WCAG 2.2 AA, read from the accessibility tree.

Checks that passed:

- Each page has one `<h1>` and no skipped heading levels.
- Every image has alt text, every link has text, and every button has a name. No link reads "here" or "read more".
- Tab order on `/` and `pipeline.html` runs from the skip link through the header to the page list. Each stop shows a focus ring.
- Text contrast meets 4.5:1, or 3:1 for large text, on `/`, `pipeline.html`, and `six-tools.html` in both themes.

| ID | Page | Finding | Evidence | Sorting | Action |
|----|------|---------|----------|---------|--------|
| A-001 | `/` | The homepage has no `<main>` landmark. Doc pages have one. The skip link to `#content` still works. | `document.querySelector('main')` returned null | backlog | 0000019 |

## Layout

**Target:** no overlap, clipping, or sideways scroll at 390 px and 1280 px, in both themes.

Checks that passed:

- No page scrolls sideways at 390 px in either theme.
- Code blocks and tables scroll inside their own boxes.
- The only element past the right edge is the homepage's decorative `abstract-shape`, which its container clips.

| ID | Page | Finding | Evidence | Sorting | Action |
|----|------|---------|----------|---------|--------|
| L-001 | All doc pages | Nested card padding narrows body text to 303 px in a 375 px viewport | `main p` on `first-run.html` at 390 px, dark theme | backlog | 0000020 |

## Content

**Target:** the repo's writing style, and facts that match the installed pack.

Checks that passed:

- `style.test.mjs` checks sentence length and banned words on every page.
- No page uses an em dash, a semicolon, or an exclamation mark in prose. A scan for American spellings found none.
- The skill and standard counts on `skills.md` and `standards.md` match the pack, at 16 and 18.
- The pages use the pack's current "initiative" term.

| ID | Page | Finding | Evidence | Sorting | Action |
|----|------|---------|----------|---------|--------|
| C-001 | `six-tools`, `project-operations`, `skills` | Eight sentences use passive voice | A scan for "is" or "are" plus a participle. Lines are listed in the backlog entry. | backlog | 0000021 |

## Performance

**Target:** page weight under 500 KB, and LCP under 2.5 s on the preview.

Every page meets both targets. The heaviest page is the homepage at 101 KB decoded. LCP ranged from 60 ms to 72 ms on the doc pages. The homepage reported no LCP entry. The weight excludes Google Fonts, because the browser reports no size for cross-origin files without timing headers.

| ID | Page | Finding | Evidence | Sorting | Action |
|----|------|---------|----------|---------|--------|
| none | | | | | |

## Navigation and metadata

**Target:** a unique `<title>` and meta description on each page, a working 404, and a favicon.

Checks that passed:

- Each page has a unique `<title>`.
- `favicon-32x32.png` returns 200.

| ID | Page | Finding | Evidence | Sorting | Action |
|----|------|---------|----------|---------|--------|
| N-003 | Repo root | Playwright MCP writes snapshots and screenshots to `.playwright-mcp/`, which git did not ignore. This run caused it. | `git status` listed `.playwright-mcp/` as untracked | fix-now | Fixed in `806f820`, size S |
| N-001 | All ten doc pages | No meta description. Only the homepage has one. | `meta[name=description]` missing on each doc page | backlog | 0000017 |
| N-002 | Any missing URL | No custom 404 page, so GitHub Pages shows its own page with no site nav | `/404.html` returned 404 | backlog | 0000018 |
