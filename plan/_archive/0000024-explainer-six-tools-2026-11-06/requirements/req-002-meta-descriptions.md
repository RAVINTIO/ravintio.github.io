---
title: "Requirement: REQ-002 - Add meta descriptions to doc pages"
summary: "Each doc page carries a unique meta description from the docs manifest."
status: "active"
version: "0.1.0"
---
# Requirement: REQ-002 - Add meta descriptions to doc pages

**Skill:** [plan](../skills/ravintio-plan/SKILL.md)
**Feature:** 0000024-explainer-six-tools
**Source:** US-002
**Priority:** must-have

## User Story

As a person who finds a page in search results, I read a summary of that page, so that I know whether to open it.

## Functional Requirements
- Each page entry in `docs.manifest.json` has a `description` field.
- `build-docs.js` writes `<meta name="description" content="…">` into each page `<head>`, with the value HTML-escaped.
- The build fails if a manifest page has no description.
- The homepage keeps its existing meta description.

## Acceptance Criteria
- [ ] AC-1: One description per page
  - Given the built doc pages
  - When a test reads each page `<head>`
  - Then each page has exactly one `<meta name="description">`
  - And its content matches the page's `description` in `docs.manifest.json`
- [ ] AC-2: Unique and sized
  - Given the `description` fields in `docs.manifest.json`
  - When a test compares and measures them
  - Then no two descriptions match, the homepage description included
  - And each runs 50 to 160 characters

## Dependencies
- None.
