---
title: "ADR 002: Run site tests in a separate pull request workflow"
summary: "A new site-tests.yml runs both suites on pull requests into main with read-only permissions. deploy.yml and ravintio.yml stay unchanged."
status: "accepted"
version: "0.1.0"
---
# ADR-002 - Run site tests in a separate pull request workflow

**Skill:** [plan](../skills/ravintio-plan/SKILL.md)
**Feature:** 0000016-site-regression-and-quality
**Component:** repo-level
**Date:** 2026-11-01

## Context

CI runs no tests today. `deploy.yml` builds and deploys on a push to `main`. `ravintio.yml` checks code and doc parity and PR attribution. Pack setup and migrations rewrite `ravintio.yml`, as migration 0005 shows.

## Decision

Add `.github/workflows/site-tests.yml`. It runs on `pull_request` into `main`, with `permissions: contents: read`. In `src/web-app`, it runs `npm ci`, installs Chromium with `--with-deps`, builds, runs `npm test`, and runs `npm run test:e2e`. On failure it uploads `playwright-report/` as an artefact. It is not a required check. The human decides that in branch protection settings.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Add steps to `ravintio.yml` | One workflow | Pack setup and migrations rewrite it | Changes could be lost on a pack update |
| Add a test job to `deploy.yml` | Tests gate deploys | Runs only after merge, on a push to `main` | Reviewers need the result before merge |

## Affected Components

| Component | Impact |
|-----------|--------|
| web-app | Its suites run in CI on each pull request |

## Consequences

**Positive:**
- Reviewers see a pass or fail on each pull request.
- The workflow stays clear of pack-managed files.

**Negative:**
- Each pull request spends a few minutes of Actions time.

**Risks:**
- The job could pass the 5-minute target as the suite grows (R-008).

## Related ADRs
- ADR-001 - depends-on: the workflow runs the Playwright suite.

## Supersedes
- none

## Superseded By
- none
