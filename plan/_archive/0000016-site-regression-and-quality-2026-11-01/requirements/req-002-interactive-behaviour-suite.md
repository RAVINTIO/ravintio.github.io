---
title: "Requirement: REQ-002 - interactive-behaviour-suite"
summary: "Detailed requirements for this specific functional feature."
status: "active"
version: "0.1.0"
---
# Requirement: REQ-002 - interactive-behaviour-suite

**Skill:** [plan](../skills/ravintio-plan/SKILL.md)
**Feature:** 0000016-site-regression-and-quality
**Source:** US-002
**Priority:** must-have

## User Story

As a contributor, I run Playwright tests on the site's interactive parts, so that the theme toggle, the mobile page list, and diagrams keep working.

## Functional Requirements
- The suite clicks `#theme-toggle` on the homepage and on one doc page, and checks `data-theme` on `<html>`.
- The theme choice persists through `localStorage` key `ravintio-theme` across a reload.
- The suite checks the `.doc-sections__disclosure` page list at 390 px and 1280 px. The breakpoint is `(max-width: 900px)`.
- The diagram test finds every `pre.mermaid` on the 11 pages. If it finds none, it calls `test.skip` with the reason `no page holds a Mermaid diagram`.

## Acceptance Criteria
- [ ] AC-1: Theme toggle switches and persists
  - Given the homepage or a doc page with no saved theme
  - When the reader clicks the theme toggle and reloads the page
  - Then `data-theme` holds the other theme after the click
  - And it still holds that theme after the reload
- [ ] AC-2: Page list collapses on a phone
  - Given a doc page at a 390 px viewport
  - When the page loads
  - Then the page list is closed
  - And a click on its summary opens it
  - But at a 1280 px viewport the page list shows open
- [ ] AC-3: Diagrams render, or the test reports a skip
  - Given the 11 pages
  - When a page holds a Mermaid diagram
  - Then each diagram renders as an SVG
  - But if no page holds one, the test reports as skipped and names the reason

## Dependencies
- REQ-001 for the config and the page list.
