---
title: "Iteration Log - 0000027-site-quality-fixes"
summary: "Execution log for the agent session."
status: "active"
version: "0.1.0"
---

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
