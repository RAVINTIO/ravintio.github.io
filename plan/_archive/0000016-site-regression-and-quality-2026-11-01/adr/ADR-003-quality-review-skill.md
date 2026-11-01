---
title: "ADR 003: Run the quality review as a capability skill from a repo instruction"
summary: "A site-quality-review capability skill, run in P3 by repo instruction custom-003, reviews the site through a pinned Playwright MCP. The run owns the report and the backlog entries it files."
status: "accepted"
version: "0.1.0"
---
# ADR-003 - Run the quality review as a capability skill from a repo instruction

**Skill:** [plan](../skills/ravintio-plan/SKILL.md)
**Feature:** 0000016-site-regression-and-quality
**Component:** repo-level
**Date:** 2026-11-01

## Context

The human wants a quality review of the site in every run. Fixes go into the run only when a finding can't wait, and the rest go to the backlog. The pack must not change, because this repo consumes it. Two repo-owned places reach every run. Each run copies `ravintio-overrides/instructions/` into `design.md`, and setup installs `ravintio-overrides/capability-skills/`.

## Decision

- `ravintio-overrides/capability-skills/site-quality-review/` holds the procedure, a report template, and the confirmed rule, cap, and duplicate check.
- Repo instruction `custom-003-site-quality-review.md` runs the skill in P3, after the Playwright suite passes.
- The skill reviews the local `vite preview` site through Playwright MCP.
- `.mcp.json` pins `@playwright/mcp` at exactly `0.0.83`.
- Data ownership: the run owns `plan/current/site-quality-report.md` and the backlog entries the review files. The report ships in the run archive. The review writes to `src/` only through a fix-now unit, under the owning component's rules.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Change the pack's P3 skill | Built into the pipeline | Changes a consumed pack | Out of scope for this repo |
| A script run in CI | Repeatable | Can't judge layout, content, or style | The review needs an agent's judgement |
| Leave Playwright MCP at user scope | No repo file | Other contributors and agents lack the tools | The human chose a project `.mcp.json` |
| `@playwright/mcp@latest` | Always current | Changes between runs, and today's release builds on an alpha | Pinned for stable tool names |

## Affected Components

| Component | Impact |
|-----------|--------|
| web-app | Reviewed each run. Fix-now findings change it. |
| site-content | Reviewed each run. Fix-now findings change it. |

## Consequences

**Positive:**
- Every run checks the site, and improvements reach the backlog instead of being lost.
- The review needs no pack change.

**Negative:**
- Each P3 takes longer.
- Review findings rest on agent judgement, so two runs can differ.

**Risks:**
- The first review may find more fix-now work than fits (R-002).
- The agent's browser could reach outside sites (R-005).

## Related ADRs
- ADR-001 - related-to: the suite runs before the review.

## Supersedes
- none

## Superseded By
- none
