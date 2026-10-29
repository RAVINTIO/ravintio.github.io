---
title: "Orchestrator reference: Skills catalogue"
summary: "Standalone and subagent skills, and the capability skill intake."
status: "active"
version: "1.0.0"
---
# Orchestrator reference: Skills catalogue

> Moved verbatim from `SKILL.md`. Read this file before you act on the topic. The Pack Index in `SKILL.md` lists the trigger.

## Standalone and Subagent Skills

| Skill | Trigger | Relationship |
|-------|---------|--------------|
| ravintio-test-writer | TDD red phase for one requirement | Subagent of implement. Never invoke independently. |
| ravintio-implementer | TDD green phase | Subagent of implement. Never invoke independently. |
| ravintio-refactor | TDD refactor phase | Subagent of implement. Never invoke independently. |
| ravintio-loop-runner | Entering any loop | Loaded by any phase agent before loop work begins. |
| ravintio-migrator | Pending migration found at session start | Standalone. Runs before any phase work. |
| ravintio-optimise-agent | Human asks to optimise or trim a skill | Standalone. Invoke any time. |
| ravintio-refresh-setup | Human asks to refresh the setup | Standalone. Invoke any time. |
| ravintio-file-backlog | Human asks to file a backlog entry in another repo | Standalone. Invoke any time. |
| ravintio-postmortem | A `Resolved:` line follows a `Blocked:` stop, or a CI failure, a P2 self-correction, an escaped defect, or the human asks | Standalone. The orchestrator runs it before ship. Invoke any time. |
| ravintio-initiative | An initiative is active and the session is not a step session, or the human asks to chart one | Standalone. The initiative hooks load it. Never runs a step. |
| ravintio-retrospective | Ship finishes the build report, I-E Delivery finishes the archive, or the human asks | Standalone. Ship and delivery run it. Invoke any time. |

## Capability Skills

Capability skills encode craft knowledge. RAVINTIO skills encode discipline. Two triggers share one intake:

- **Arrival:** a `SKILL.md` appears in `ravintio-zero/skills-inbox/`, checked at discovery start action 14 and every phase transition.
- **Proposal:** after the gate checklist passes and before design confirmation, assess the declared stack against known capability skills. If relevant ones are not installed, ask once, without pressure.

**Intake:** read the skill's frontmatter and summarise it in one sentence. Ask: `Use for this plan only, or add permanently? (plan / permanent)`. Plan: move to `plan/current/capability-skills/{name}/`. Permanent: move to `ravintio-overrides/capability-skills/{name}/` and re-run setup. Clear the inbox if that was the trigger, update `## Active Skills` in `design.md`, report the result. Declines proceed silently. A deferred arrival re-presents at the next transition. Before adding any skill, apply the skill-scope test: does it provide governance or traceability the host tool cannot provide on its own.
