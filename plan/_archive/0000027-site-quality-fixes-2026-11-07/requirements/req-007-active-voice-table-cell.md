---
title: "Requirement: REQ-007 - Name the actor in a project operations table cell"
summary: "One table cell on the project operations page states who acts."
status: "active"
version: "0.1.0"
---
# Requirement: REQ-007 - Name the actor in a project operations table cell

**Skill:** [plan](../skills/ravintio-plan/SKILL.md)
**Feature:** 0000027-site-quality-fixes
**Source:** US-007
**Priority:** should-have

## User Story

As a reader, I read a project operations table cell that names who acts, so that I know who commits the CI gate.

## Functional Requirements
- The `ravintio.yml` row in `src/site-content/pages/project-operations.md` reads "The CI gate works only after you commit it."
- A content test pins the new cell and rejects "only works once committed".

## Acceptance Criteria
- [ ] AC-1: Named actor
  - Given `project-operations.md`
  - When a test reads the `.github/workflows/ravintio.yml` table row
  - Then the cell reads "The CI gate works only after you commit it."
  - And the page no longer holds "only works once committed"

## Dependencies
- None.
