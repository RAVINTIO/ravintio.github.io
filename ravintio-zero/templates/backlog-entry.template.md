---
title: "Backlog Entry: {{id}} - {{short-title}}"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future discovery run."
status: "open"  # open | parked
---
# Backlog Entry: {{id}} - {{short-title}}

> Path: `plan/backlog/{id}-{slug}/entry.md`: one folder per entry, `{id}` zero-padded sequence, `{slug}` kebab-case.
>
> **`{id}` comes from the counter file.** Reserve it with
> `node ravintio-zero/scripts/reserve-id.mjs` before you write the entry. The script
> reads `plan/backlog/.next-id` under a lock and never hands out an id twice, so
> picked-up and discarded ids stay spent. Backlog, feature, and initiative ids share
> the counter.
>
> **A copied entry gets a local id.** If you copy an entry from another repo, reserve
> a new id from this repo's counter and name the source repo and the source id in the
> entry text. Each repo keeps its own sequence.
>
> **Deferral source** distinguishes why the entry exists: `discovered mid-flight`
> (a surprise found during a run, judged out of scope on the spot; today's only
> case for ad hoc filings), `deliberate scope decision` (a call already made and
> reasoned through in the source feature's own `scope.md`/ADRs; this entry
> points back at that reasoning rather than repeating it), or `tech debt`
> (acknowledged debt filed alongside the code that incurred it). Entries routed
> automatically from a `recommendations.md` Deferred Items or Tech Debt row use
> `deliberate scope decision` or `tech debt` respectively; entries filed live
> during a run use `discovered mid-flight`.
>
> Use `human request` when the human asks for the entry directly, rather than
> a run finding it. If no run is active, write `none (human request)` for the
> source feature and source phase.
>
> A parked entry comes from the orchestrator's park command. Its frontmatter
> status is `parked`, and its `**Parked branch:**` field names the feature branch
> that holds the shelved work. Other entries keep status `open` and leave the
> field out.

**Source feature:** {{feature-id that discovered this | none (human request)}}
**Source phase:** {{P0–P4 phase active when discovered | none (human request)}}
**Deferral source:** {{discovered mid-flight | deliberate scope decision | tech debt | human request}}
**Date filed:** {{ISO-8601 date}}
**Parked branch:** {{feature branch, for a parked entry only | omit for an open entry}}

---

## Problem

{{What was discovered. Specific enough that a future discovery run (with no memory of this
session) can judge whether to pull it in. Name files/paths where relevant.}}

## Suggested Action

{{One or two sentences: what fixing it would look like. A suggestion, not a spec;
scope is decided at pickup.}}

## Why Deferred

{{Why this was not folded into the active feature: out of scope / non-blocking /
would need its own design decision.}}
