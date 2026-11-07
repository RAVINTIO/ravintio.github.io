---
title: "Requirement: REQ-003 - Add a main landmark to the homepage"
summary: "The homepage gains one main element, and every page keeps exactly one."
status: "active"
version: "0.1.0"
---
# Requirement: REQ-003 - Add a main landmark to the homepage

**Skill:** [plan](../skills/ravintio-plan/SKILL.md)
**Feature:** 0000027-site-quality-fixes
**Source:** US-003
**Priority:** should-have

## User Story

As a screen reader user, I jump to the homepage main content by landmark, so that I skip the header as I can on doc pages.

## Functional Requirements
- `src/web-app/index.html` wraps the content below the site header in `<main id="content">`.
- The `id="content"` moves from the hero header to `<main>`, so the skip link still lands on the content.
- The page health suite checks every page for exactly one `<main>`.

## Acceptance Criteria
- [ ] AC-1: Homepage main
  - Given the built homepage
  - When the browser loads `/`
  - Then the page has one `<main id="content">`
  - And the skip link `href="#content"` targets it
- [ ] AC-2: One main per page
  - Given each page path from `pages.ts`
  - When the page health suite loads it
  - Then the page has exactly one `<main>`

## Dependencies
- None.
