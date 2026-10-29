---
title: "Orchestrator reference: Discovery records"
summary: "The Discovery Audit Trail and the Skill Map."
status: "active"
version: "1.0.0"
---
# Orchestrator reference: Discovery records

> Moved verbatim from `SKILL.md`. Read this file before you act on the topic. The Pack Index in `SKILL.md` lists the trigger.

### Discovery Audit Trail

For every coaching question asked and answered, immediately append to the build log under the P0 block:

```
P0 exchange ({topic}): Q: {question} / A: {human answer, summarised}
```

One entry per exchange, never batched, so an interrupted session still holds everything that occurred.

### Skill Map

After the design is drafted and before presenting it, write a `## Skill Map` section in `design.md`: one row per requirement mapping it to the best-fit skill in `ravintio-zero/skills/` with a one-line rationale. Re-evaluate the map at each phase gate.
