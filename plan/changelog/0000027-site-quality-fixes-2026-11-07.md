---
title: "Iteration Log - 0000027-site-quality-fixes"
summary: "Execution log for the agent session."
status: "active"
version: "0.1.0"
---

# Changelog (0000027-site-quality-fixes, 07 Nov 2026)

**Feature:** Close seven site quality findings
**Version:** 0.7.0
**PR:** pending

## What changed

- The Playwright suite now runs an axe-core WCAG 2.2 AA scan of every page in light and dark. A serious or critical violation fails the pull request.
- The first scan found two serious issues, and both are fixed. The pagination title now meets 4.5:1 contrast in light theme. Wide code blocks now take keyboard focus.
- A custom 404 page with the site header and links home now serves any missing path, at any depth.
- The homepage wraps its content in `<main id="content">`. Each page has exactly one `<main>`.
- The skip link now moves keyboard focus to the content, not only the scroll position.
- Doc page text on phones widens from 317 px to about 333 px at a 390 px viewport.
- Every action in `site-tests.yml` and `deploy.yml` now runs at a pinned commit SHA.
- The header and footer code links point to the RAVINTIO organisation, labelled "RAVINTIO on GitHub".
- One project operations table cell now names who acts.

## Why

The run 0000016 and 0000024 quality reviews left seven findings open (backlog 0000015, 0000018, 0000019, 0000020, 0000022, 0000025, and 0000026). A manual review missed accessibility rules that an engine checks on every element.

## Deviations

- Vite 7 preview has no 404 page support, so `vite.config.ts` adds a preview plugin that serves `dist/404.html`.
- The phone width test measures `main h1`, because the sitemap has no paragraph.
- The quality review fixed a skip-link focus issue that predates this run and fails WCAG level A.
- Backlog 0000037, a 404 skip link issue with JavaScript off, stays in the backlog. The review's rule would sort it as fix-now.
- P1 wrote its plan inline. P2 ran batch 1 as three parallel TDD tracks and batches 2 to 5 inline.

## Validation results

- `npm test`: 93 of 93 pass. `npx playwright test`: 92 pass, 1 existing skip.
- Axe: 26 of 26 page and theme pairs pass, with no moderate or minor finding.
- Typecheck, build, and `npm audit` pass with 0 vulnerabilities.
- Security: overall low, with no critical, high, or medium finding.
- All 14 criteria verified by execution.

## Skipped phases

None.

# Iteration Log - 0000027-site-quality-fixes

> **Audience:** The ship phase's build assessment (P4) and post-run technical review. This is NOT the PR changelog: the PR changelog (written at the start of ship) is the human-readable audit trail for PR reviewers.

**Skill:** [implement](../skills/ravintio-implement/SKILL.md)
**Date:** 2026-11-07

## Iteration Steps Completed

| Phase | Status | Gate Result | Notes |
|-------|--------|-------------|-------|
| P0 - Discovery | pass | Design confirmed: yes | 8 backlog decisions, scope lock accepted in one reply |
| P1 - Plan | pass | All artifacts produced: yes | 4 ADRs, consistency check clean on the second pass |
| P2 - Implement | pass | Implementation complete: yes | 1 self-correction, 2 improvement cycles |

## Requirement Changes During Run

| Change | Phase Active | Classification | Action Taken |
|--------|-------------|----------------|-------------|
| REQ-002 links are relative and resolve through `<base href="/">`. A preview plugin serves the 404 page. | P2 | deviation | Updated REQ-002 |
| REQ-004 AC-1 measures `main h1`, because the sitemap has no paragraph | P2 | deviation | Updated REQ-004 |
| REQ-001 scans the sitemap, so `pagePaths()` lists it | P2 | deviation | Recorded in the build log |

## Self-Correct Log

No TDD track needed a second attempt. The U7 Playwright run failed the phone-width test on the sitemap, and the run's own check missed it because `tail -2` hid the failed line. The improvement review caught it:

- `c53fe90`: the width test measures `main h1`, and the axe spec asserts the theme before each scan.
- `97522c8`: the pin test parses fixture workflow text, so it can fail. The 404 preview plugin handles a malformed URL and checks the `dist` path with a separator.

## Axe findings fixed

- `color-contrast` (serious): the pagination title used `opacity: 0.7`, which failed in light theme on every doc page. It now uses `--text-muted`.
- `scrollable-region-focusable` (serious): a wide code block on `first-run.html`. Every code `<pre>` now takes `tabindex="0"`.

## Quirks

- Vite 7 preview has no 404 page support, so `vite.config.ts` adds a preview plugin.
- The 404 page assumes the domain root.

## Recommended Improvements

- Review the 404 page copy and the organisation link label.
- Add Dependabot for GitHub Actions, so the SHA pins get bump pull requests.
