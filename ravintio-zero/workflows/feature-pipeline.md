---
name: feature-pipeline
description: Run the RAVINTIO pipeline from feature brief to merged PR. The single route for every change.
---

# Feature Pipeline

The single route through RAVINTIO. Every change runs this pipeline.

## Every change is a feature change

There is one route. A small change is a small run: fewer requirements, a
shorter plan, and a quicker pass through the same five gates. It is not a
different route.

## Prerequisites

- A feature brief at `plan/current/feature-brief.md`.
- If you don't have one, use the
  [feature brief template](../templates/feature-brief.template.md).

## Phases

The pipeline has five phases. The orchestrator owns discovery and drives the
run. Each later phase is owned by its own skill, which the orchestrator
invokes in order.

| # | Phase | Owner | Produces |
|---|-------|-------|----------|
| 1 | Discovery | ravintio-orchestrator | `plan/current/discovery.md`, confirmed `plan/current/design.md` |
| 2 | Plan | ravintio-plan | Requirements at `plan/current/requirements/`, ADRs at `plan/current/adr/` |
| 3 | Implement | ravintio-implement | Code, tests, and docs at `src/{component-id}/` |
| 4 | Validate and accept | ravintio-validate-and-accept | Passing CI, security review, verified acceptance criteria |
| 5 | Ship | ravintio-ship | Archive, build assessment, changelog, tag, PR |

### P0: Discovery

The orchestrator reads the brief, coaches the human through gaps one question
at a time, picks up backlog entries, locks scope, and writes the design.

**Gate: design confirmation.** The human confirms `plan/current/design.md`.
That confirmation ends discovery. No later phase starts without it.

### P1: Plan

ravintio-plan produces one artifact set: the execution plan, functional
requirements, scope, risk register, glossary, and an ADR for every
significant decision.

**Gate: the plan gate.** One gate for the whole artifact set. Requirements
and ADRs are confirmed together, not separately.

### P2: Implement

ravintio-implement builds the feature through a TDD loop per requirement.
Code, tests, and docs land together. Code never ships without its
documentation.

**Gate: the implement gate.** Every requirement has code, tests, and docs,
and the implementation matches the confirmed plan.

### P3: Validate and accept

ravintio-validate-and-accept runs CI (lint, typecheck, test, build),
self-corrects up to 5 times, performs the security review, and verifies
acceptance criteria by running the software.

**Gate: human acceptance.** In gated mode, the human accepts the working
feature. In autonomous mode, the acceptance evidence goes in the PR
description instead.

### P4: Ship

ravintio-ship archives `plan/current/` to `plan/_archive/{feature-id}/`,
files the build assessment, writes the changelog entry, tags the release,
and raises the PR.

**Gate: the ship gate.** In gated mode, the human confirms the result before
the PR. In autonomous mode, the agent raises the PR and stops. The human
merges the PR in every mode.

## Run modes

At the end of discovery, the orchestrator asks how to run P1 to P4. It records
the answer in `plan/.run-mode` and logs it in the build log.

- **Gated**: the pipeline stops for the human at the plan, implement,
  acceptance, and ship gates.
- **Autonomous**: the pipeline stops at none of those gates. It runs to a
  raised PR and ends with `P4 Ship: Complete: PR #{n} ready for your review`.

The orchestrator then asks for a run speed and records it in `plan/.run-speed`.
At `fast`, each phase dispatches its listed fast batch in one message. At
`standard`, or when the file is missing, each phase applies its own rules.
Phases run in order at either speed, and every gate stays in place.

Both modes stop for escalations. Each stop prints `{prefix} Blocked:` and names
the action the human needs to take. The five escalations are:

- A check still fails after 5 attempts.
- Implement needs a schema change.
- The security review finds an unmitigated critical or high issue.
- A push or `gh pr create` fails.
- A possible credential appears in a file the run will commit, or in the PR body.

Design confirmation always involves the human, because the run mode is chosen
in that conversation. Merging the PR is human-only in every mode.
