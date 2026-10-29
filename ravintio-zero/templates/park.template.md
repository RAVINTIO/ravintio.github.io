---
phase: "{phase-id}"
last_artifact: "{path to the last file written or action completed}"
head_commit: "{short SHA of the feature branch head when park.md is written}"
reason: "{why the human parked the feature, in one sentence}"
---
# Park Record - {feature-id}

**Parked:** {ISO-8601 datetime}
**Phase:** {phase-id} ({phase name})
**Branch:** {feature branch, for example feat/{feature-id}}

> If `plan/current/design.md` does not exist, the phase reached is P0.

## State at Park

{Free-text description of what is done and what remains. Name the requirement or
task in progress, any decisions pending, and any blockers. Write enough for the
orchestrator to rebuild the full context on resume without the earlier
conversation.}

## Resume Instructions

A later P0 backlog pickup offers resume or discard for the parked entry. On
resume, the orchestrator checks out the branch and merges `origin/main`. It then
restores state from this file and opens with:

```
{phase-id}: Resuming parked feature: {feature-id}
```

The orchestrator deletes this file and the parked entry folder in one commit on
the feature branch.
