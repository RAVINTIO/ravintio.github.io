---
title: "Requirement: REQ-006 - no-white-flash"
summary: "Detailed requirements for this specific functional feature."
status: "active"
version: "0.1.0"
---
# Requirement: REQ-006 - no-white-flash

**Skill:** [plan](../skills/ravintio-plan/SKILL.md)
**Feature:** 0000016-site-regression-and-quality
**Source:** US-006
**Priority:** must-have

## User Story

As a reader, I see my chosen theme from the first frame, so that pages don't flash white on load.

## Functional Requirements
- `index.html` and the page template in `build-docs.js` hold an inline script at the top of `<head>`, before any stylesheet.
- The inline script sets `data-theme` on `<html>` from `localStorage` key `ravintio-theme`. With no saved value, it uses `prefers-color-scheme`.
- If `localStorage` throws, the inline script falls back to `prefers-color-scheme` and logs no error.
- Both templates hold `<meta name="color-scheme" content="light dark">`.
- `main.ts` keeps the toggle and reads the theme the inline script set.
- The Playwright test checks `data-theme` and the computed `<html>` background at `DOMContentLoaded`, before the module script runs.

## Acceptance Criteria
- [ ] AC-1: Saved dark paints dark first
  - Given `ravintio-theme` holds `dark`
  - When the homepage or a doc page loads
  - Then `data-theme` is `dark` and the background is the dark palette before the module script runs
- [ ] AC-2: Saved light paints light first
  - Given `ravintio-theme` holds `light`
  - When the homepage or a doc page loads
  - Then `data-theme` is `light` before the module script runs
- [ ] AC-3: No saved choice follows the system
  - Given no saved theme and a dark colour-scheme preference
  - When the homepage or a doc page loads
  - Then `data-theme` is `dark` before the module script runs

## Dependencies
- REQ-001 for the suite config.

## Input Validation
- [ ] Input source: `localStorage` key `ravintio-theme`
- [ ] Allowed character pattern: the exact values `light` or `dark`. Any other value falls back to `prefers-color-scheme`.
- [ ] maximum length: 5 characters. A longer value counts as invalid.
- [ ] Failure behaviour: fall back to `prefers-color-scheme` and continue.
- [ ] Logging policy: raw value not logged.
