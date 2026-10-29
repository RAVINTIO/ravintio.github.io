---
title: "Postmortem: {{date}} - {{short-title}}"
summary: "A blameless record of why a failure got through earlier phases, and the actions that close the gap."
status: "open"  # open | closed
---
# Postmortem: {{date}} - {{short-title}}

> Path: `plan/postmortems/{date}-{slug}.md`. Written by `ravintio-postmortem`.
> Blameless: a cause names a gap in a process, check, standard, or tool. Never name a person or an agent.
> Copy no credential from a log. Name the file and the line instead.

**Trigger:** {{failed CI run | Blocked stop | P2 self-correction | escaped defect | human request}}
**Feature:** {{feature-id or none}}
**Date:** {{date}}

## Summary

{{One or two sentences: what failed and what the impact was.}}

## Timeline

| Time | Event | Evidence |
|------|-------|----------|
| {{timestamp}} | {{event}} | {{build-log line, commit, CI log line, or file path}} |

First missed chance to catch it: {{event and the check or phase that could have caught it}}

## 5 whys

1. {{Why 1: the failure}}
2. {{Why 2}}
3. {{Why 3}}
4. {{Why 4}}
5. {{Why 5: a gap in a process, check, standard, or tool}}

**Gap:** {{the process, check, standard, or tool gap the chain ends at}}

## Actions

| Type | Action | Owner | Lives in | Verified by | Filed as |
|------|--------|-------|----------|-------------|----------|
| {{corrective | preventive | detective}} | {{action}} | {{owner}} | {{path}} | {{test, check, or review}} | {{backlog entry id or repo instruction path}} |
