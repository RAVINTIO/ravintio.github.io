---
title: "Requirement: REQ-006 - dependency-advisories"
summary: "Detailed requirements for this specific functional feature."
status: "active"
version: "0.1.0"
---
# Requirement: REQ-006 - dependency-advisories

**Skill:** [plan](../skills/ravintio-plan/SKILL.md)
**Feature:** 0000009-bug-fixes
**Source:** US-006
**Priority:** must-have

## User Story

As the site maintainer, I build the site with no known advisories in its dependencies, so that the build chain stays safe.

## Functional Requirements
- `npm audit fix` in `src/web-app` updates `vite`, `mermaid`, and their transitive dependencies within their current majors.
- The run adds no new dependency and makes no major version bump.
- If the update changes built output or breaks a test, the unit stops and reports. It never loosens a test.

## Acceptance Criteria
- [ ] AC-1: No advisories
  - Given `src/web-app` after the update
  - When `npm audit` runs
  - Then it reports 0 vulnerabilities
- [ ] AC-2: Build and tests pass
  - Given `src/web-app` after the update
  - When `npm run build` and `npm test` run
  - Then both exit 0

## Dependencies
- None.
