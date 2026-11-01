---
title: "ADR 001: Add Playwright for browser tests beside node --test"
summary: "Playwright 1.64.1 on Chromium runs browser tests against vite preview. The node --test suite stays. This supersedes 0000005 ADR-001."
status: "accepted"
version: "0.1.0"
---
# ADR-001 - Add Playwright for browser tests beside node --test

**Skill:** [plan](../skills/ravintio-plan/SKILL.md)
**Feature:** 0000016-site-regression-and-quality
**Component:** web-app
**Date:** 2026-11-01

## Context

0000005 ADR-001 kept the Vite stack and put every test on `node --test`, with no new dependency. Those tests read source and built HTML as text. They can't see console errors, rendered layout, the theme on first paint, or script behaviour. The confirmed design for this run adds a browser suite, and the human approved `@playwright/test` `1.64.1`.

## Decision

Add `@playwright/test` `1.64.1` as an exact dev dependency in `src/web-app`. The suite runs on Chromium only, with `retries: 0`, against the built site served by `vite preview`. It lives in `tests/e2e/` and runs with `npm run test:e2e`. The `node --test` suite stays as the content suite and runs with `npm test`. Patch updates within `1.64.x` are allowed. Any other version change needs human approval.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Keep `node --test` only, with `jsdom` | No browser download | No real layout, paint, or console. `jsdom` is a new dependency too. | Can't test REQ-001 AC-3 or REQ-006 |
| Playwright on Chromium, Firefox, and WebKit | Wider engine coverage | Triple run time for a static site with little engine-specific code | The human chose Chromium only |
| Cypress | Mature runner | Heavier install, and no MCP tie-in for the quality review | Playwright shares its engine with Playwright MCP |

## Affected Components

| Component | Impact |
|-----------|--------|
| web-app | New dev dependency, config, `test:e2e` script, and `tests/e2e/` |

## Consequences

**Positive:**
- Browser-only breakage shows before merge.
- The suite and the quality review use the same engine.

**Negative:**
- Contributors download Chromium once, about 150 MB.
- Two test runners to keep current.

**Risks:**
- The first-frame test may be timing-sensitive (R-001).

## Related ADRs
- ADR-002 - depends-on: CI runs this suite.
- ADR-004 - related-to: the suite tests the inline theme script.

## Supersedes
- 0000005 ADR-001 (Keep the Vite stack and test with the Node test runner)

## Superseded By
- none
