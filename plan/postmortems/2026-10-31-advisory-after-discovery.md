---
title: "Postmortem: 2026-10-31 - Advisory appeared after discovery"
summary: "A blameless record of why a failure got through earlier phases, and the actions that close the gap."
status: "open"
---
# Postmortem: 2026-10-31 - Advisory appeared after discovery

> Path: `plan/postmortems/{date}-{slug}.md`. Written by `ravintio-postmortem`.
> Blameless: a cause names a gap in a process, check, standard, or tool. Never name a person or an agent.
> Copy no credential from a log. Name the file and the line instead.

**Trigger:** Blocked stop
**Feature:** 0000009-bug-fixes
**Date:** 2026-10-31

## Summary

P2 stopped on REQ-006 AC-1. `npm audit` still reported 2 low advisories after the approved fix. The only fix was `mermaid` 12, a major bump outside the approved list. The stop cost about 90 minutes of waiting and no rework.

## Timeline

| Time | Event | Evidence |
|------|-------|----------|
| P0, before 2026-10-31T13:14:15Z | Discovery found that `npm audit fix` cleared all 16 advisories within current majors | `plan/_archive/0000009-bug-fixes-2026-10-31/build-log.md`, P0 exchange (dependencies) |
| 2026-10-31T13:14:15Z | The design approved patch and minor updates within current majors only | `design.md`, `Approved dependencies` |
| 2026-10-31T13:33:23Z | P1 planned U6 from the P0 result. No audit ran. | P1 block start, `execution-plan.md` U6 row |
| 2026-10-31T13:41:05Z | U6 ran `npm audit fix`. 2 low advisories remained (GHSA-238p-pmpm-9mq7 in `katex` 0.16.47). | Build log `Blocked:` line, commit `1097472` |
| 2026-10-31T15:11:10Z | The human approved `mermaid` 12. The audit then reported 0. | Build log `Resolved:` line, commit `977c976` |

First missed chance to catch it: P1. A fresh audit at the plan gate would have shown the new advisory before implementation started.

## 5 whys

1. P2 stopped because the approved fix left 2 low advisories.
2. A new advisory reached the dependency tree after the P0 audit, and only a major bump fixes it.
3. The approved list bounded updates to current majors, based on the P0 snapshot.
4. No phase re-runs the audit between discovery and implement, so the bound was never rechecked.
5. The pack has no audit refresh in P1 and no coaching on approval scope for advisory-fix stories.

**Gap:** `ravintio-plan` has no dependency audit refresh, and discovery coaching doesn't ask whether a major bump is pre-approved for an advisory fix.

## Actions

| Type | Action | Owner | Lives in | Verified by | Filed as |
|------|--------|-------|----------|-------------|----------|
| corrective | Approve `mermaid` 12 and upgrade | human | `design.md`, `src/web-app/package.json` | `npm audit` reports 0 | Build log `Resolved:` line |
| detective | Re-run the dependency audit in P1 when a requirement targets advisories | pack maintainer | `ravintio-zero/skills/ravintio-plan/SKILL.md` | A pack test on the plan skill | [backlog 0000010](../backlog/0000010-refresh-audit-before-implement/entry.md) |
| preventive | Ask in discovery whether a major bump is pre-approved for an advisory fix | pack maintainer | orchestrator discovery coaching reference | A pack test on the coaching reference | [backlog 0000011](../backlog/0000011-approve-dependency-outcomes/entry.md) |
