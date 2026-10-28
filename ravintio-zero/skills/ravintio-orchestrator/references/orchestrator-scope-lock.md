---
title: "Orchestrator reference: Scope lock challenge"
summary: "The Scope Lock Challenge gate that runs before the design is presented."
status: "active"
version: "1.0.0"
---
# Orchestrator reference: Scope lock challenge

> Moved verbatim from `SKILL.md`. Read this file before you act on the topic. The Pack Index in `SKILL.md` lists the trigger.

### Scope Lock Challenge

Run this after coaching Q&A completes and before presenting the design. It is a mandatory gate.

An initiative step self-confirms this gate as I-C Run in `ravintio-zero/standards/roadmap-standards.md` describes.

Read `plan/current/feature-brief.md`. If `## Scenario Paths` is filled in, use the human's four paths. Otherwise derive them from the user stories and acceptance criteria. The four questions:

1. **Happy path:** the end-to-end flow when everything works. First action, and what success looks like.
2. **First-run path:** the very first use, before any prior data or state exists.
3. **Error path:** the most likely failure mode and what should happen.
4. **Cross-session continuity:** what state is at risk if the session is interrupted, and how it is recovered.

**Draft inline.** Draft all four suggested answers yourself, in this context. Do not dispatch a subagent. Drafting rules: frame from usage, describe outcome not implementation, write an honest "not applicable" where true, and check each draft against decisions the human has already confirmed. Surface any contradiction alongside the draft rather than resolving it silently.

**Present as a batch.** Show all four questions with their labelled drafts in a single turn. Label every draft as a draft, never as a decided answer.

**Confirmation is human-only, per item.** Only the human's explicit accept, edit, or reject for each individual item counts as scope confirmation. Silence is never approval. The conversation moving on is never approval. A blanket "looks fine" across the batch is never approval for any single item. Your own draft is never confirmation, no matter how confident it reads.

**Record immediately.** The moment the human confirms one item, append to the build log under the P0 block, before handling the next item:

```
Scope Lock ({path type}): {one-sentence summary} [source: human | draft-accepted | draft-edited]
```

If an answer reveals a scope gap, ask one clarifying question, capture the answer in the same format, then return to the batch. If the human defers an item: `Scope Lock, deferred: {description} (blocked until {dependency})`. When all four are captured, confirm: "Scope Lock complete. All four scenario paths captured."
