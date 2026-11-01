---
title: "Requirement: REQ-001 - page-health-suite"
summary: "Detailed requirements for this specific functional feature."
status: "active"
version: "0.1.0"
---
# Requirement: REQ-001 - page-health-suite

**Skill:** [plan](../skills/ravintio-plan/SKILL.md)
**Feature:** 0000016-site-regression-and-quality
**Source:** US-001
**Priority:** must-have

## User Story

As a contributor, I run a Playwright suite that loads every page in a real browser, so that broken pages, links, and mobile layouts show before merge.

## Functional Requirements
- `src/web-app` adds `@playwright/test` `1.64.1` as an exact dev dependency and a `playwright.config.ts`.
- The config runs Chromium only, with `retries: 0`. Its `webServer` serves the existing build with `vite preview` on a fixed local port.
- `npm run test:e2e` runs the suite. Tests live in `src/web-app/tests/e2e/`.
- The page list comes from `docs.manifest.json` plus the homepage, so a new manifest page joins the suite with no test edit.
- The suite fails any page that logs a console error or an uncaught page error.

## Acceptance Criteria
- [ ] AC-1: Every page loads cleanly
  - Given the built site served by `vite preview`
  - When the suite opens the homepage and each manifest page
  - Then each response has status 200
  - And no page logs a console error or an uncaught page error
- [ ] AC-2: Internal links and anchors resolve
  - Given the same 11 pages
  - When the suite follows each internal link
  - Then each target returns status 200
  - And each `#fragment` matches an element id on the target page
- [ ] AC-3: No sideways scroll on a phone
  - Given a 390 px wide viewport
  - When each of the 11 pages loads
  - Then the document's scroll width is no greater than the viewport width

## Dependencies
- None. REQ-002, REQ-003, and REQ-006 build on this suite.
