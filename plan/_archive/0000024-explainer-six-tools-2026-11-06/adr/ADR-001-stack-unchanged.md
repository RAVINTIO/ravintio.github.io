---
title: "ADR 001: Keep the declared stack"
summary: "The run adds no dependency and keeps the stack from the design."
status: "accepted"
version: "0.1.0"
---
# ADR-001 - Keep the declared stack

**Skill:** [plan](../skills/ravintio-plan/SKILL.md)
**Feature:** 0000024-explainer-six-tools
**Date:** 2026-11-06

## Context

The design declares TypeScript, Vite 7, `marked`, `mermaid` 12, `node --test`, and `@playwright/test`. The design approves no new dependency. A voice check could use a prose linter such as `write-good`.

## Decision

Keep the declared stack. Write the voice check as a regex test in `style.test.mjs`, beside the existing word blocklist.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Add `write-good` | Tested passive detection | New dependency outside the approved list, and its own false positives | The design approves no dependency |

## Affected Components

| Component | Impact |
|-----------|--------|
| web-app | No new package. The voice check lives in the existing test file. |

## Consequences

**Positive:**
- No dependency exception stop and no new supply chain.

**Negative:**
- The regex misses irregular participles outside its list.

**Risks:**
- R-001: the allowlist grows.

## Related ADRs

- 0000016 ADR-001 Playwright browser tests - related-to
