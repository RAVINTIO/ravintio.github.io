---
title: "Requirement: REQ-005 - mobile-section-nav"
summary: "Detailed requirements for this specific functional feature."
status: "active"
version: "0.1.0"
---
# Requirement: REQ-005 - mobile-section-nav

**Skill:** [plan](../skills/ravintio-plan/SKILL.md)
**Feature:** 0000009-bug-fixes
**Source:** US-005
**Priority:** must-have

## User Story

As a reader on a phone, I see the page content first, with the page list collapsed, so that I don't scroll past ten links to start reading.

## Functional Requirements
- `build-docs.js` wraps the section nav in a native `<details open>` element. Its `<summary>` names the current page.
- Below 900 px, `main.ts` removes the `open` attribute on load, so the list starts closed.
- At 900 px and above, CSS hides the `<summary>` and the sidebar looks as it does in 0.4.0.
- Without JavaScript, the list stays open and renders as a plain list.
- At 360 px the page has no horizontal scroll.

## Acceptance Criteria
- [ ] AC-1: Closed on a phone with the heading in view
  - Given any built page at a 360 by 740 px viewport
  - When the page loads
  - Then the page list is closed and the summary names the current page
  - And the first page heading sits inside the first viewport with no horizontal scroll
- [ ] AC-2: Keyboard toggle exposes its state
  - Given a built page at 360 px wide
  - When the reader tabs to the summary and presses Enter or Space
  - Then the page list opens and the disclosure reports its expanded state
- [ ] AC-3: Desktop sidebar unchanged
  - Given a built page at 1280 px wide
  - When the page loads
  - Then the sidebar shows every section and page link as in 0.4.0, with no visible summary
  - And every built page holds the nav inside a `<details>` element with a `<summary>`

## Dependencies
- None.
