---
title: "ADR 001: Keep the Vite stack and test with the Node test runner"
summary: "The site keeps Vite, marked, and mermaid, and adds tests that run on node --test with no new dependency."
status: "accepted"
version: "0.1.0"
---
# ADR-001 - Keep the Vite stack and test with the Node test runner

**Skill:** [plan](../skills/ravintio-plan/SKILL.md)
**Feature:** 0000005-ravintio-docs-rewrite
**Component:** web-app
**Date:** 2026-10-29

## Context

The confirmed design keeps the existing stack and approves no new dependency. `web-app` has no automated tests today. Its manifest lists that as tech debt. Six acceptance criteria need automated checks.

## Decision

Keep Vite 7, `marked`, `mermaid`, and TypeScript as declared in `design.md`. Add tests in `src/web-app/tests/*.test.mjs` that run with `node --test`. Add an `npm test` script that runs them after `npm run build`. Tests use only Node built-ins (`node:test`, `node:assert`, `node:fs`, `node:path`).

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Vitest | Richer output, watch mode | New dependency, not on the approved list | Dependency exception stop |
| Playwright for nav and links | Tests the rendered DOM | Heavy dependency, browser download in CI | Not approved, and static HTML parsing covers the criteria |
| Shell scripts with grep | No runtime needed | Hard to keep portable across Bash versions | Node is already required for the build |

## Affected Components

| Component | Impact |
|-----------|--------|
| web-app | Gains `tests/`, an `npm test` script, and a `testing: node-test` stack entry |

## Consequences

**Positive:**
- The run adds no dependency and no supply-chain surface.
- Tests run anywhere the build runs.

**Negative:**
- HTML checks parse built files with regular expressions rather than a DOM, which limits how deep they can inspect structure.

**Risks:**
- A regex-based link check misses a link form it doesn't expect. Mitigation: `build-docs.js` emits links in one known form.

## Related ADRs

- ADR-004 - related-to
- ADR-005 - related-to

## Supersedes

- none

## Superseded By

- none
