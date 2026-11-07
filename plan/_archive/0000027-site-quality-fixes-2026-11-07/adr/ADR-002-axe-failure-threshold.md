---
title: "ADR 002: Fail the suite on serious and critical axe violations"
summary: "Serious and critical violations fail CI, and the P3 review triages the rest."
status: "accepted"
version: "0.1.0"
---
# ADR-002 - Fail the suite on serious and critical axe violations

**Skill:** [plan](../skills/ravintio-plan/SKILL.md)
**Feature:** 0000027-site-quality-fixes
**Component:** web-app
**Date:** 2026-11-07

## Context

Backlog 0000015 leaves open which axe violations fail the suite. Failing on every impact would block pull requests on minor findings. Failing on none would make the scan advisory only.

## Decision

A serious or critical violation fails the test for that page and theme. The spec writes moderate and minor violations to `test-results/axe-report.json`. The P3 `site-quality-review` reads that report and sorts each finding as fix-now or backlog.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Fail on every impact | Strictest | Minor findings block merges | Too much friction for a docs site |
| Report only | No CI friction | A regression ships unseen | Defeats the purpose of the scan |

## Affected Components

| Component | Impact |
|-----------|--------|
| web-app | The new spec sets the threshold. |

## Consequences

**Positive:**
- Severe regressions fail the pull request, and minor ones still reach a reviewer.

**Negative:**
- Moderate findings can build up if P3 files them to the backlog each run.

**Risks:**
- R-002: Mermaid SVG findings may need a human-approved exclusion.

## Related ADRs

- ADR-001 Add axe-core to the declared stack - builds-on
- 0000016 ADR-003 Run the quality review as a capability skill from a repo instruction - related-to
