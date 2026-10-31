---
title: "ADR 001: Keep the stack and patch dependencies within current majors"
summary: "The site keeps its declared stack and clears advisories with npm audit fix inside current majors, adding no dependency."
status: "accepted"
version: "0.1.0"
---
# ADR-001 - Keep the stack and patch dependencies within current majors

**Skill:** [plan](../skills/ravintio-plan/SKILL.md)
**Feature:** 0000009-bug-fixes
**Component:** web-app
**Date:** 2026-10-31

## Context

The confirmed design keeps the declared stack: Markdown content, Node 24, Vite 7, `marked`, `mermaid`, TypeScript, and `node --test`. `npm audit` reports 16 advisories in `src/web-app`. In P0, the agent found that `npm audit fix` clears all 16 within current majors, with `vite` 7.3.7 and `mermaid` 11.17.2. The design approves no new dependency. Data ownership stays as recorded in ADR-002 of run `0000005`: `site-content` owns the pages and `web-app` reads them at build time.

## Decision

Keep the declared stack. Run `npm audit fix` without `--force` in `src/web-app` and commit the updated `package.json` and `package-lock.json`. Accept only patch and minor updates of existing dependencies. Tests for this run use Node built-ins only, as in 0.4.0.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| `npm audit fix --force` | Clears advisories that need a major bump | May bump majors and change behaviour | Not needed. The non-forced fix clears all 16. |
| Leave the advisories | No change risk | Known vulnerabilities stay in the build chain | Fails US-006 |
| Replace `mermaid` with prebuilt SVG diagrams | Removes the largest dependency | New build step and a stack change not in the design | Out of scope |

## Affected Components

| Component | Impact |
|-----------|--------|
| web-app | `package.json` ranges and `package-lock.json` change. No code change from this decision. |

## Consequences

**Positive:**
- `npm audit` reports 0 advisories with no new supply-chain surface.
- The stack and test approach stay the same, so no doc or skill change follows.

**Negative:**
- Minor updates of `mermaid` can change diagram rendering, which only a browser check catches.

**Risks:**
- A transitive update breaks the build. Mitigation: `npm run build` and `npm test` run in the same unit, which stops and reports on failure.

## Related ADRs

- ADR-002 - related-to

## Supersedes

- none

## Superseded By

- none
