---
title: "ADR 001: Add axe-core to the declared stack"
summary: "The run adds @axe-core/playwright as its one dev dependency."
status: "accepted"
version: "0.1.0"
---
# ADR-001 - Add axe-core to the declared stack

**Skill:** [plan](../skills/ravintio-plan/SKILL.md)
**Feature:** 0000027-site-quality-fixes
**Component:** web-app
**Date:** 2026-11-07

## Context

The design declares TypeScript, Vite 7, `marked`, `mermaid` 12, `node --test`, and `@playwright/test`. Backlog 0000015 asks for automated accessibility rules. The P3 review judges WCAG 2.2 AA by hand and misses rules that an engine checks on every element. The design approves `@axe-core/playwright` as a dev dependency.

## Decision

Keep the declared stack and add `@axe-core/playwright` to `devDependencies` at an exact version. Run it from a new Playwright spec beside the existing suite.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Keep the manual review only | No dependency | Misses rules on elements the reviewer doesn't read | The backlog entry exists because of this gap |
| `pa11y-ci` | Standalone runner | A second browser stack beside Playwright | Duplicates the Playwright setup |

## Affected Components

| Component | Impact |
|-----------|--------|
| web-app | One new dev dependency and one new spec. |

## Consequences

**Positive:**
- CI checks every page in both themes against the WCAG 2.2 AA rule set.

**Negative:**
- One more package in the supply chain, and a longer Playwright run.

**Risks:**
- R-001 and R-002: the first scan finds violations to fix.

## Related ADRs

- 0000016 ADR-001 Add Playwright for browser tests beside node --test - related-to
