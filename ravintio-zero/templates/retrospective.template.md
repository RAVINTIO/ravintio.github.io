---
title: "Retrospective: {{date}} - {{short-title}}"
summary: "A blameless review of a finished run or initiative, and the changes it files."
status: "open"  # open | closed
---
# Retrospective: {{date}} - {{short-title}}

> Path: `plan/retrospectives/{feature-id}-{date}.md` for a run, `plan/retrospectives/{id}-{slug}-initiative-{date}.md` for an initiative. Written by `ravintio-retrospective`.
> Blameless: a cause names a gap in a process, check, standard, or tool. Never name a person or an agent.
> Copy no credential from a log. Name the file and the line instead.

**Mode:** {{run | initiative}}
**Subject:** {{feature-id, or initiative id and slug}}
**Date:** {{date}}

## Summary

{{One or two sentences: what shipped and how the work went.}}

## What helped

- {{observation}} ({{evidence}})

## What slowed the work

- {{observation}} ({{evidence}})

## Initiative questions

<!-- Initiative mode only. Delete this section in run mode. -->

1. Charted versus shipped (steps, bumps, versions): {{answer}}
2. Friction that repeated across steps: {{answer}}
3. Each stop and how long each step took: {{answer}}
4. Initiative tooling gaps: {{answer}}

## Keep

- {{at least one thing to keep}} ({{evidence}})

## Change

- {{at least one thing to change}} ({{evidence}})

## Actions

| Change | Owner | Lives in | Verified by | Filed as |
|--------|-------|----------|-------------|----------|
| {{change}} | {{owner}} | {{path}} | {{test, check, or review}} | {{backlog entry id or repo instruction path, naming this retrospective}} |
