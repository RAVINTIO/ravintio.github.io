---
title: "Requirement: REQ-006 - Point the code links to the RAVINTIO organisation"
summary: "The header and footer code links lead to all six tools."
status: "active"
version: "0.1.0"
---
# Requirement: REQ-006 - Point the code links to the RAVINTIO organisation

**Skill:** [plan](../skills/ravintio-plan/SKILL.md)
**Feature:** 0000027-site-quality-fixes
**Source:** US-006
**Priority:** should-have

## User Story

As a reader, I follow the header and footer code links to the RAVINTIO organisation, so that I see all six tools, not only Zero.

## Functional Requirements
- The header code link and the footer **GitHub** link in `src/web-app/index.html` point to `https://github.com/RAVINTIO`.
- `REPO_URL` in `scripts/build-docs.js` becomes `ORG_URL` with the same value, so every doc page matches.
- The header link's `aria-label` and `title` read "RAVINTIO on GitHub".
- The 404 page header matches.
- In-body links to the Zero repo in `six-tools.md` and `install-zero.md` stay.

## Acceptance Criteria
- [ ] AC-1: Organisation target
  - Given the built homepage, 404 page, and every doc page
  - When a test reads the header code link and the footer GitHub link
  - Then both point to `https://github.com/RAVINTIO`
- [ ] AC-2: Matching label
  - Given the same pages
  - When a test reads the header code link
  - Then its `aria-label` and `title` read "RAVINTIO on GitHub"

## Dependencies
- REQ-002, whose 404 page header this covers.
