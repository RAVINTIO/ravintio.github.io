---
title: "Requirement: REQ-003 - zero-reference"
summary: "Detailed requirements for this specific functional feature."
status: "active"
version: "0.1.0"
---
# Requirement: REQ-003 - zero-reference

**Skill:** [plan](../skills/ravintio-plan/SKILL.md)
**Feature:** 0000005-ravintio-docs-rewrite
**Source:** US-003
**Priority:** must-have

## User Story

As a Zero user, I look up a skill, standard, or template, so that I can check what the pack provides.

## Functional Requirements
- Page 8, "Skills", lists every folder in `ravintio-zero/skills/` with its name and a one-line purpose from its `SKILL.md` description.
- Page 9, "Standards", lists every file in `ravintio-zero/standards/` (top level) with a one-line purpose.
- Page 10, "Templates", lists every file in `ravintio-zero/templates/` with a one-line purpose.
- Each item appears as a heading or table row whose name matches the pack file or folder name in code font.
- The pages name no item that is absent from the pack.

## Acceptance Criteria
- [ ] AC-1: Reference pages present in order
  - Given the site is built
  - When a reader opens the Reference nav section
  - Then it lists "Skills", "Standards", and "Templates" in that order
- [ ] AC-2: Every pack item is documented
  - Given the pack folders `skills/`, `standards/`, and `templates/`
  - When the reference test lists their items
  - Then each item name appears on its reference page
- [ ] AC-3: No item outside the pack is documented
  - Given the reference pages
  - When the reference test reads each documented item name
  - Then each name exists in the matching pack folder

## Dependencies
- REQ-004 for the nav sections and the `site-content` component.
