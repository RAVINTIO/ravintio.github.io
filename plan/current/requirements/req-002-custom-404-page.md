---
title: "Requirement: REQ-002 - Add a custom 404 page"
summary: "The build writes a 404 page with the site header that works at any path depth."
status: "active"
version: "0.1.0"
---
# Requirement: REQ-002 - Add a custom 404 page

**Skill:** [plan](../skills/ravintio-plan/SKILL.md)
**Feature:** 0000027-site-quality-fixes
**Source:** US-002
**Priority:** should-have

## User Story

As a reader who follows a broken link, I see a site page with links back to the docs, so that I can find what I wanted.

## Functional Requirements
- `src/web-app/404.html` holds the site header, a heading, a short message, and links to the homepage and the sitemap.
- `vite.config.ts` lists `404.html` as a build input, so the build writes `dist/404.html`.
- The page sets `<base href="/">`, so its assets and links resolve at any path depth (ADR-003).
- The page has a unique `<meta name="description">` and a `<title>`.
- The page uses the theme script, so it follows the reader's theme.

## Acceptance Criteria
- [ ] AC-1: Built with header and links
  - Given a production build
  - When a test reads `dist/404.html`
  - Then it holds the site header, one `<h1>`, a link to `/`, and a link to `/docs/sitemap.html`
- [ ] AC-2: Works at a nested path
  - Given the preview server serves `dist/404.html` at `/docs/missing/page.html`
  - When the browser loads that path
  - Then the stylesheet and script load with status 200 and the console shows no errors

## Dependencies
- None.
