---
name: ravintio-loop-runner
description: Canonical loop mechanics for every pipeline loop: state file conventions, stop rules, escalation format, toggle protocol. Loaded by any phase agent entering a loop.
---

# RAVINTIO - loop-runner

> You define how every loop in the pipeline behaves. Loops iterate. You make sure they iterate *boundedly*, *observably*, and *recoverably*. Any phase agent that runs a loop loads this skill for the mechanics and defines only its own rubric and pass condition.

## Hard Limits

1. **Every loop has an armed stop rule before its first iteration.** No cap, no loop.
2. **Agents write `plan/current/.ratchet-approve` only on explicit human instruction, never on their own initiative.** The human must state the path, the reason, and the go-ahead in the same turn. The line format is `path | reason | timestamp` with the human's exact reason text transcribed verbatim. A reason containing a `|` character invalidates the line (strict 3-field parse, fails closed). Commit the write immediately, in its own dedicated commit, before any further work proceeds: the hook's same-uncommitted-changeset backstop blocks the guarded edit if this step is skipped. Writing the marker without that explicit in-the-moment instruction is a violation, not a workaround.
3. **Budget counters are never reset by an agent.** They live in the loop-state file, are git-tracked, and survive interrupt/resume.
4. **Run-log records are append-only.** Never rewrite a prior iteration's record.

## Toggle Protocol

Before arming any loop, read `ravintio-overrides/loop-toggles.yml` (see `ravintio-zero/templates/loop-toggles.template.yml`):

- Absent file, absent key, or unreadable/invalid value → the loop is **off**. Emit a one-line warning only for an invalid value on a known key.
- `report-only` → run the loop, write findings/verdicts, block nothing, mutate nothing.
- `on` → verdicts gate progression per the owning skill's rules.

The pipeline never creates `ravintio-overrides/loop-toggles.yml`. Enabling a loop is always a deliberate human act.

## Loop State (per instance)

Create `plan/current/loop-state-{loop-id}.md` from `ravintio-zero/templates/loop-state.template.md` when the loop arms. Update and **commit after every iteration**: the state file is how an interrupted session resumes mid-loop (the `{phase-prefix}: Resuming` convention), and how budget counters survive resume.

While any loop-state file has `status: active`, the `ratchet-check.mjs` hook is armed for `plan/current/` artifact writes. Set `status: done` or `status: escalated` when the loop exits. Never leave a dead loop armed.

## The Iteration Cycle

```
while state.status == active:
  1. ACT      : do one bounded unit of loop work (one critique pass, one fix, one verification)
  2. OBSERVE  : collect the evidence (findings, check output, observed behaviour)
  3. RECORD   : append one run-log record: action, observation, decision
  4. DECIDE   : continue | done | escalate, per the stop rules below
```

One iteration = one record. Doing three passes and logging one record is a defect.

## Stop Rules

Armed on every loop, checked at every DECIDE:

| Rule | Trigger | Action |
|------|---------|--------|
| Pass | The owning skill's pass condition is met | `done`: set state, disarm |
| Iteration cap | iteration == cap (default **3**, the validate-and-accept CI loop uses **5**, a skill may declare its own) | `escalate` |
| no-progress | The same gap/finding survives **2 consecutive iterations** without measurable change | `escalate`: do not spend the remaining cap restating the problem |

Caps and budgets are enforced by orchestrator control flow reading the state file, not by this text.

## Escalation Format

On `escalate`, populate the state file's Escalation Context section (stop rule hit, outstanding finding, attempts summary, recommended next step) and emit, using the owning phase's prefix, such as `P3 Validate:`:

```
{phase-prefix} Blocked ({loop-id}): {one-line outstanding finding}
Escalation context: plan/current/loop-state-{loop-id}.md
```
