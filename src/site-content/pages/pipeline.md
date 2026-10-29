# The pipeline

Every change in Zero runs through the same five phases. This page explains what each phase produces, how gates and run modes work, and how you control a run.

## The five phases

| Phase | Prefix | Skill | Main output |
|-------|--------|-------|-------------|
| P0 Discovery | `P0 Discovery:` | `ravintio-orchestrator` | `plan/current/design.md`, `discovery.md`, `build-log.md` |
| P1 Plan | `P1 Plan:` | `ravintio-plan` | Requirements, scope, risks, glossary, and decision records |
| P2 Implement | `P2 Implement:` | `ravintio-implement` | Code, tests, and documentation |
| P3 Validate | `P3 Validate:` | `ravintio-validate-and-accept` | Check results, security findings, and execution evidence |
| P4 Ship | `P4 Ship:` | `ravintio-ship` | Changelog, archive, build report, and pull request |

For the full skill list, see [skills](skills.md).

### P0 Discovery

The orchestrator assesses your brief and coaches you through the gaps. It detects the adoption mode, reads the version, and records its findings in `discovery.md`. It ends with the Scope Lock Challenge and the design for your confirmation. After you confirm, the design does not change unless you use the mid-pipeline change protocol. A mid-pipeline change is a requirement change while P1 to P3 runs. The agent sorts it as cosmetic, additive, or contradictory and re-runs from the earliest affected phase.

### P1 Plan

The plan phase always produces these artefacts in `plan/current/`.

- `execution-plan.md`, with non-functional requirements and a concurrency plan
- `story-map.md`
- `requirements/`, with one file per user story
- `scope.md`, which states what is in, out, and deferred
- `risk-register.md`
- `domain-glossary.md`
- `adr/`, with one decision record per significant decision

Some artefacts appear only when their trigger holds. Examples are an OpenAPI specification for a feature that changes an API, and an operational model for a deployed service. Each component also gets a `component.yml` manifest under `src/`.

### P2 Implement

For each requirement, the agent runs a test-driven loop. It writes one failing test, writes the minimum code to pass, and then refactors. An improvement loop follows, with up to two cycles per requirement. Documentation lands in the same phase as the code.

### P3 Validate

The agent runs these checks in order.

1. Library audit
2. Semantic correctness, meaning each requirement has an executing test
3. Lint
4. Typecheck
5. Test
6. Build

On a failure, it fixes the root cause and re-runs. After five failed cycles, it stops. A security review and an execution check follow. The agent never weakens a test to make an error go away.

### P4 Ship

Ship writes the changelog to `plan/changelog/`, archives `plan/current/` to `plan/_archive/{feature-id}-{date}/`, and writes a build report. It deletes the run sentinels after it confirms the archive and before it pushes, so no pull request carries them. It then raises the pull request. CI tags the merge commit after you merge.

## Response prefixes and statuses

Every reply in an active run starts with `{prefix} {Status}: {one-liner}`.

| Status | Meaning |
|--------|---------|
| `Starting` | The phase begins. |
| `Resuming` | The agent found existing artefacts and continues from them. |
| `Complete` | The phase finished. |
| `Blocked` | The agent needs your decision before it continues. |
| `Skipped` | The phase did not run, and the reply gives the reason. |

```text
P1 Plan: Starting: producing requirements and decision records
P3 Validate: Skipped: skipped by request
```

A hook warns when a reply lacks a valid prefix. It logs the miss and never blocks.

## Gates and run modes

At the end of discovery, you choose a run mode. The agent saves it in `plan/.run-mode`.

| Mode | Behaviour |
|------|-----------|
| Gated | The agent stops for you at the plan, implement, acceptance, and ship gates. |
| Autonomous | The agent runs to a raised pull request. It stops only for escalations. |

In an autonomous run, validate puts its evidence in `plan/current/acceptance-evidence.md`. Ship copies it into the pull request description. You review it there.

In both modes, merging the pull request stays with you.

## Run speed

After the run mode, you choose a run speed. The agent saves it in `plan/.run-speed`.

| Speed | Behaviour |
|-------|-----------|
| Standard | Each phase applies its own parallelism rules. |
| Fast | Each phase dispatches the units in its fast batch list, each batch in one message. |

A missing or unknown value counts as standard. Phases run in order at either speed, and every gate and escalation stays in place.

## The Scope Lock Challenge

The challenge runs after discovery questions and before the design. The agent drafts four scenario paths from your brief. You review each one.

| Path | Question |
|------|----------|
| Happy path | What does the end-to-end flow look like when everything works? |
| First-run path | What happens on first use, before any state exists? |
| Error path | What is the most likely failure, and what should happen? |
| Cross-session continuity | What state is at risk if the session stops, and how is it recovered? |

Only your explicit accept, edit, or reject for each item counts. Silence does not count. Each confirmed item goes into the build log at once. If you defer an item, the agent records what blocks it.

## Exception stops

Both run modes stop on these exceptions.

- A requirement or check still fails after five attempts.
- Implementation needs a schema change.
- The security review finds an unmitigated critical or high issue.
- A push or pull request command fails.
- A possible credential appears in a file the run will commit.
- A phase adds a library or service that is not on the approved list.

At a stop, the agent writes a `Blocked:` line to the build log, prints the message, and waits. When you act, it writes a `Resolved:` line. A resumed run never passes an open stop. The agent never works round a stop.

## Pause, park, and resume

You control a run with plain words in the chat.

| Command | What happens |
|---------|--------------|
| Pause | The agent writes `plan/current/pause.md` and stops. A new session that loads the orchestrator resumes at the exact point. |
| Park | The agent writes `plan/current/park.md` on the feature branch and pushes it. It files a `parked` backlog entry through a chore pull request and returns the working tree to `main`. |
| Resume | The orchestrator reads the signals in `plan/current/` and the build log. It opens with `Resuming` and restores the run mode without asking. |

Park never merges a pull request and never commits to `main`. The parked entry reaches `main` only when you merge the chore pull request. Later, discovery offers to resume or discard the parked feature.

## Skip a phase

If you ask to skip a phase, the agent acknowledges and does not argue. It appends a line to `plan/current/.skips` with the date and your reason. Ship reads that file into the changelog.

## Archiving at ship

At ship, the agent moves the run's artefacts out of `plan/current/`.

| Location | Contents |
|----------|----------|
| `plan/_archive/{feature-id}-{date}/` | The archived plan, the build log, and the build report |
| `plan/changelog/{feature-id}-{date}.md` | The changelog entry |

For the other controls, see [project operations](project-operations.md).
