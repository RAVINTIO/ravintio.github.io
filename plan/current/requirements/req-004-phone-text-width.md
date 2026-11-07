---
title: "Requirement: REQ-004 - Widen the text column on phones"
summary: "Doc page body text uses most of a phone screen."
status: "active"
version: "0.1.0"
---
# Requirement: REQ-004 - Widen the text column on phones

**Skill:** [plan](../skills/ravintio-plan/SKILL.md)
**Feature:** 0000027-site-quality-fixes
**Source:** US-004
**Priority:** should-have

## User Story

As a reader on a phone, I read a text column that uses most of the screen, so that lines don't wrap after five words.

## Functional Requirements
- Below 600 px, `src/web-app/src/style.css` reduces the side padding of the page list card and the content card.
- Desktop and tablet layouts stay as they are.
- The existing 390 px sideways-scroll check in `page-health.spec.ts` keeps passing.

## Acceptance Criteria
- [ ] AC-1: Wide text column
  - Given a 390 by 844 viewport
  - When the browser loads each doc page
  - Then the first `main p` is at least 330 px wide
- [ ] AC-2: No sideways scroll
  - Given a 390 by 844 viewport
  - When the browser loads each page
  - Then the document scroll width is no wider than the viewport

## Dependencies
- None.
