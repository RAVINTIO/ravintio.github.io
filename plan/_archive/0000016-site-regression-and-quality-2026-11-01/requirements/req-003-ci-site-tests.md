---
title: "Requirement: REQ-003 - ci-site-tests"
summary: "Detailed requirements for this specific functional feature."
status: "active"
version: "0.1.0"
---
# Requirement: REQ-003 - ci-site-tests

**Skill:** [plan](../skills/ravintio-plan/SKILL.md)
**Feature:** 0000016-site-regression-and-quality
**Source:** US-003
**Priority:** must-have

## User Story

As a reviewer, I see both test suites run on each pull request, so that I know the site builds and passes before I merge.

## Functional Requirements
- `.github/workflows/site-tests.yml` runs on `pull_request` into `main`.
- The workflow sets `permissions: contents: read`.
- In `src/web-app`, the job runs these steps in order: `npm ci`, `npx playwright install --with-deps chromium`, `npm run build`, `npm test`, and `npm run test:e2e`.
- On failure, the job uploads `playwright-report/` with `actions/upload-artifact`.
- A `node --test` test checks the workflow's trigger, permissions, steps, and upload.
- `deploy.yml` and `ravintio.yml` stay unchanged.

## Acceptance Criteria
- [ ] AC-1: Both suites run on each pull request
  - Given a pull request into `main`
  - When GitHub Actions runs `site-tests.yml`
  - Then the job builds the site, runs `npm test`, and runs `npm run test:e2e`
- [ ] AC-2: A failed test fails the job and keeps the report
  - Given a Playwright test that fails
  - When the job runs
  - Then the job fails
  - And the Playwright report is uploaded as a workflow artefact
- [ ] AC-3: The suite is fast and stable
  - Given a local build
  - When `npm run test:e2e` runs three times in a row with `retries: 0`
  - Then all three runs pass and each takes under 60 s
  - And the CI job takes under 5 min

## Dependencies
- REQ-001 and REQ-002 for the suite the job runs.
