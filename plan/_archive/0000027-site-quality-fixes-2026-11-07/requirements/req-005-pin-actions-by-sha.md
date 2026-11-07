---
title: "Requirement: REQ-005 - Pin workflow actions by commit SHA"
summary: "Every action in the site workflows runs at a fixed commit."
status: "active"
version: "0.1.0"
---
# Requirement: REQ-005 - Pin workflow actions by commit SHA

**Skill:** [plan](../skills/ravintio-plan/SKILL.md)
**Feature:** 0000027-site-quality-fixes
**Source:** US-005
**Priority:** should-have

## User Story

As a maintainer, I run CI actions pinned by commit SHA, so that a moved tag can't change the code CI runs.

## Functional Requirements
- Each `uses:` line in `.github/workflows/site-tests.yml` and `deploy.yml` names a full 40-character commit SHA.
- A comment after each SHA names the tag it resolves, such as `# v5`.
- The SHA is the commit the current tag points to, read with `gh api`. No major version changes.
- `site-tests-workflow.test.mjs` checks both files.
- `ravintio.yml` stays as `setup.sh` writes it (ADR-004).

## Acceptance Criteria
- [ ] AC-1: Pinned with tag comments
  - Given `site-tests.yml` and `deploy.yml`
  - When a reader checks each `uses:` line
  - Then each names `owner/repo@{40 hex characters}` followed by `# v{n}`
- [ ] AC-2: Test enforces pins
  - Given a `uses:` line in either file that names a tag or a short SHA
  - When `npm test` runs
  - Then `site-tests-workflow.test.mjs` fails and names the line

## Dependencies
- None.
