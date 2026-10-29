---
title: "Initiative: {{id}} - {{short-title}}"
summary: "{{One sentence: what this initiative delivers.}}"
status: "proposed"  # proposed | charted | active | delivered | blocked
---
# Initiative: {{id}} - {{short-title}}

> Path: `plan/roadmap/{id}-{slug}/initiative.md` for a draft, one folder per draft. `{id}` is a
> zero-padded seven-digit number and `{slug}` is kebab-case. An active initiative lives at
> `plan/current-initiative/initiative.md`.
>
> **`{id}` shares the backlog's sequence.** Reserve each `{id}` from `plan/backlog/.next-id`
> with `node ravintio-zero/scripts/reserve-id.mjs [qty]`. Reserve one block for the
> initiative and its step feature ids.
>
> `Bump` takes `major`, `minor`, or `patch`. Leave it empty for the default, `minor`.
> `position` names the next step to run.
>
> `## Schema changes` lists each step's predicted data change. The human approves the rows at
> Chart. See Chart-time schema approval in `ravintio-zero/standards/roadmap-standards.md`.
>
> `## Dependencies` lists each step's predicted library or service. The human approves the rows
> at Chart. See Chart-time dependency approval in the same file.
>
> `## Decisions`, `## Baselines`, and `## Criteria` hold the Chart-time decisions. The human
> approves the rows at Chart. See Chart-time decisions in the same file.

**Goal:** {{What the whole chain delivers, in one or two sentences.}}
**Branch:** initiative/{{id}}-{{slug}}
**Status:** {{proposed | charted | active | delivered | blocked}}
**Position:** {{number of the next step to run, for example 1}}
**Speed:** {{standard | fast, optional, a missing field means standard}}

## Stop conditions

- {{A condition that halts the chain, for example a step blocks or a CI run fails twice.}}

## Schema changes

**Unpredicted additive changes:** {{pre-approved | stop}}

| Step | Component | Change | Kind |
|------|-----------|--------|------|
| 1 | {{component id, or none}} | {{the predicted data change, or none}} | {{additive, destructive, or none}} |

## Dependencies

| Step | Name | Kind | Purpose |
|------|------|------|---------|
| 1 | none | none | {{the library or service the step adds, or none. Kind is library, service, or none}} |

## Decisions

| Step | Fork | Pre-approved answer | Bump effect |
|------|------|---------------------|-------------|
| 1 | {{a likely fork, or none}} | {{the answer, and any fallback scope it adds}} | {{the bump change, or none}} |

## Baselines

| Step | Target | Baseline | Source |
|------|--------|----------|--------|
| 1 | {{a speed or size target, or none}} | {{where the cost goes}} | {{the profile taken at Chart}} |

## Criteria

| Step | Criterion | Noise and margin | Checked in |
|------|-----------|------------------|------------|
| 1 | {{a measurable criterion, or none}} | {{noise across runs, and whether the margin covers it}} | {{local | CI}} |

## Steps

| Step | Feature id | Backlog entries | Bump | Version | Status |
|------|------------|-----------------|------|---------|--------|
| 1 | {{feature id}} | {{backlog ids}} | minor | | pending |
