---
title: "Site quality report: 0000027-site-quality-fixes"
summary: "Findings from the P3 site quality review, sorted into fix-now and backlog."
---
# Site quality report: 0000027-site-quality-fixes

| Field | Value |
|-------|-------|
| Feature id | 0000027-site-quality-fixes |
| Date | 2026-11-07 |
| Pages reviewed | 14: the homepage, `/404.html`, a nested missing path (`/docs/missing/page.html`), the sitemap, and the ten manifest pages |
| Preview URL | http://localhost:4173 |

## Summary

| Area | Fix-now | Backlog |
|------|---------|---------|
| Accessibility | 1 (fixed) | 0 |
| Layout | 0 | 1 (new 0000038) |
| Content | 0 | 0 |
| Performance | 0 | 0 |
| Navigation and metadata | 0 | 1 (new 0000037) |

Backlog entries 0000018, 0000019, and 0000020 are fixed in this run. The review verified each one.

## Accessibility

**Target:** WCAG 2.2 AA, read from the accessibility tree.

| ID | Page | Finding | Evidence | Sorting | Action |
|----|------|---------|----------|---------|--------|
| A-001 | Every page | The skip link scrolled to `#content` but left keyboard focus on the link. The next Tab landed on the nav logo, so the skip link bypassed nothing. | Tab then Enter then Tab on `/docs/skills.html` focused the logo link (`../index.html`). On `/404.html` the URL stayed on the page, but focus stayed on the link. Fails WCAG 2.4.1 (level A). | fix-now (S) | Fixed in `7b8fb25`. The handler now sets `tabindex="-1"` and focuses the target. Three new Playwright tests cover `/`, `/404.html`, and `/docs/pipeline.html` |
| A-002 | All 14 pages | No other accessibility finding. Heading order has no skips and each page has one `h1` and one `<main>`. No control or link lacks a name, and no image lacks `alt`. No computed text colour fails 4.5:1 in either theme at either width, including the pagination title in `--text-muted`. The axe report (`src/web-app/test-results/axe-report.json`) is empty. | `browser_evaluate` scan over 14 pages, 2 widths, 2 themes. Code `<pre>` elements that scroll carry `tabindex="0"`. The organisation link reads "RAVINTIO on GitHub". | none | none |

## Layout

**Target:** no overlap, clipping, or sideways scroll at 390 px and 1280 px, in both themes.

| ID | Page | Finding | Evidence | Sorting | Action |
|----|------|---------|----------|---------|--------|
| L-001 | `/docs/pipeline.html` and other pages with wide tables, at 390 px | Inline `code` in table cells breaks mid-word ("rav / int / io- / orch"). The table scrolls sideways inside its wrapper. | Screenshot of `/docs/pipeline.html` at 390 px in the dark theme. The page does not scroll sideways on any of the 14 pages (`scrollWidth` equals the viewport). | backlog | 0000038 |
| L-002 | All doc pages at 390 px | Verified fixed: the text column is wide enough after the slimmer card padding. | The width test passes. Screenshot shows the body text filling the card. | none | 0000020 fixed in this run |

## Content

**Target:** the repo's writing style, and facts that match the installed pack.

| ID | Page | Finding | Evidence | Sorting | Action |
|----|------|---------|----------|---------|--------|
| none | All | No finding. A search of `src/site-content/pages/` found no banned word and no em dash or semicolon in prose. The reference-match test confirms the Skills, Standards, and Templates pages list the installed pack. 0000026 (the passive table cell) stays fixed. | `grep` over the page Markdown, and `reference-match.test.mjs` passing | none | none |

## Performance

**Target:** page weight under 500 KB, and LCP under 2.5 s on the preview.

| ID | Page | Finding | Evidence | Sorting | Action |
|----|------|---------|----------|---------|--------|
| none | All | No finding. The homepage weighs 119 KB with fonts. Doc pages weigh 38 KB or less. LCP is 36 to 56 ms on every page that reports one. The homepage reports no LCP entry. | Sum of response body sizes, and a buffered LCP observer | none | none |

## Navigation and metadata

**Target:** a unique `<title>` and meta description on each page, a working 404, and a favicon.

| ID | Page | Finding | Evidence | Sorting | Action |
|----|------|---------|----------|---------|--------|
| N-001 | `/404.html` and any missing path | With JavaScript off, the skip link resolves to `/#content` because of `<base href="/">` and loads the homepage. With JavaScript on, `main.ts` intercepts the click and the visitor stays on the page. | Keyboard check on `/404.html` and `/docs/missing/page.html`: Tab, Enter kept the URL. The `href` resolves to `/#content` under `<base>`. | backlog | 0000037 |
| N-002 | `/docs/missing/page.html` | Verified fixed: a missing path returns status 404 and serves the custom page with the site header and two links. The one console error is the browser's own 404 resource line. | HTTP status 404, title "Page not found | RAVINTIO Docs". | none | 0000018 fixed in this run |
| N-003 | Homepage | Verified fixed: the homepage has one `<main id="content">`. | `document.querySelectorAll('main').length` returned 1 | none | 0000019 fixed in this run |
| N-004 | All 14 pages | No other finding. Every page has a unique `<title>`, one meta description, `lang="en-GB"`, and a favicon that loads. All internal links and anchors return 200. The four external links are the GitHub organisation (labelled "RAVINTIO on GitHub" and "GitHub") and the two repositories. | `browser_evaluate` and request checks over 13 pages | none | none |
