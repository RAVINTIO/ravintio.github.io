---
title: "ADR 004: Pin actions by SHA in the site workflows only"
summary: "The run pins actions in site-tests.yml and deploy.yml and leaves the pack workflow alone."
status: "accepted"
version: "0.1.0"
---
# ADR-004 - Pin actions by SHA in the site workflows only

**Skill:** [plan](../skills/ravintio-plan/SKILL.md)
**Feature:** 0000027-site-quality-fixes
**Component:** web-app
**Date:** 2026-11-07

## Context

Security finding S-001 from run 0000016 rates tag references in the workflows as low risk. A moved tag would run different code in CI. Three workflows exist. `site-tests.yml` and `deploy.yml` belong to `web-app`. `ravintio-zero/setup.sh` writes `ravintio.yml`, so a setup refresh would undo any edit there.

## Decision

Pin every `uses:` line in `site-tests.yml` and `deploy.yml` to the full commit SHA of its current tag, with the tag in a trailing comment. Leave `ravintio.yml` as setup writes it. `site-tests-workflow.test.mjs` enforces the pins in the two site workflows.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Pin all three workflows | Covers every action | Setup overwrites `ravintio.yml` | The pins would not last |
| Keep tags | No upkeep | Leaves S-001 open | The backlog entry asks for pins |

## Affected Components

| Component | Impact |
|-----------|--------|
| web-app | Two workflow files and one test change. |

## Consequences

**Positive:**
- CI runs the action code that was current at pin time.

**Negative:**
- Each pin needs a manual or Dependabot bump to take a security release.

**Risks:**
- R-005 and R-006.

## Related ADRs

- 0000016 ADR-002 Run site tests in a separate pull request workflow - related-to
