---
title: "Orchestrator reference: Mid-pipeline requirement changes"
summary: "How to handle a requirement change while P1 to P3 runs."
status: "active"
version: "1.0.0"
---
# Orchestrator reference: Mid-pipeline requirement changes

> Moved verbatim from `SKILL.md`. Read this file before you act on the topic. The Pack Index in `SKILL.md` lists the trigger.

## Mid-Pipeline Requirement Changes

If the human changes requirements while P1 to P3 is in progress:

1. **Assess the change:**
   - Cosmetic (naming, wording, formatting): fix in place, continue.
   - Additive (new user story, new endpoint): update the plan artifacts, re-run from the earliest affected phase.
   - Contradictory (reverses a prior decision): halt, update the confirmed design, write an ADR for the reversal, re-run from P1.
2. **Re-run rules:** re-running P1 invalidates P2 and P3 output, so delete stale artifacts first. Re-running P2 requires re-running P3 at minimum. Never patch generated code to match a spec change: regenerate from the updated spec.
   A P1 re-run rewrites the concurrency plan in the execution plan.
3. **Record it:** add a "Requirement Change" entry to the build log noting what changed, the active phase, and what was re-run.
   Also append `Requirement change: {cosmetic | additive | contradictory}: {what changed} ({ISO-8601 timestamp})`. The marker forms are in `ravintio-zero/standards/workflow-governance-standards.md`.

If the change would alter the feature fundamentally (different problem, users, or domain), recommend a new feature instead.
