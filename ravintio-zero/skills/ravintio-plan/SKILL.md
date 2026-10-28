---
name: ravintio-plan
description: Produces the plan-phase artifact set (requirements, ADRs, scope, risks, glossary) behind one human gate. Invoked by the orchestrator during the plan phase.
---

# RAVINTIO - plan

> You produce the full requirements-and-decisions artifact set for a feature behind one human gate. You work from a confirmed design and feature brief. You derive requirements. You never invent them.

**Prefix.** Begin every reply with `P1 Plan:`, in the form `{prefix} {Status}: {one-liner}`, as in `P1 Plan: Starting: {one-liner}`.

**Pack files.** Read each of these from the pack folder before the step that uses it:

- `ravintio-zero/templates/execution-plan.template.md`
- `ravintio-zero/templates/scope.template.md`
- `ravintio-zero/templates/risk-register.template.md`
- `ravintio-zero/templates/domain-glossary.template.md`
- `ravintio-zero/templates/component.template.yml`
- `ravintio-zero/templates/component-guide.md`
- `ravintio-zero/templates/data-contract.template.md`
- `ravintio-zero/templates/data-contract-guide.md`
- `ravintio-zero/standards/formatting-standards.md`

**One question at a time.** When you need human input, ask one question and wait.

## Input

- Confirmed design at `plan/current/design.md`
- Feature brief at `plan/current/feature-brief.md`
- Existing domain knowledge at `plan/` (if retrofit or change)

If the adoption mode is retrofit, work from the retrofit scan recorded in `plan/current/discovery.md`. The execution plan must describe the system as it exists and what is changing, not the change in isolation.

## Artifacts

Write each artifact to disk as you complete it. Do not accumulate artifacts in memory. Each artifact follows its template in `ravintio-zero/templates/` where one exists.

**Minimal default set - always produced, regardless of feature size:**

| Artifact | Path |
|---|---|
| Execution plan | `plan/current/execution-plan.md` - NFRs plus API and data summary |
| Story map | `plan/current/story-map.md` - activities, steps, and gaps, from `ravintio-zero/templates/story-map.template.md` |
| Functional requirements | `plan/current/requirements/` - one granular file per user story |
| Scope | `plan/current/scope.md` - in, out, and deferred all stated explicitly |
| Risk register | `plan/current/risk-register.md` |
| Domain glossary | `plan/current/domain-glossary.md` |
| ADRs | `plan/current/adr/ADR-{NNN}-{title}.md` - one per significant decision |

**Conditional set - produced only when its trigger holds.** A trigger is declared in the feature brief or inferred from a stated property of the confirmed design, never from feature size or story count. Absent a trigger, omit the artifact entirely. No empty or N/A placeholder files.

| Artifact | Path | Trigger |
|---|---|---|
| OpenAPI specification | `plan/current/openapi-spec.yaml` | The feature builds or modifies an API. Omit for pure UI, daemons, and libraries |
| Operational model | `plan/current/operational-model.md` | The feature introduces or modifies a deployed runtime service |
| SLO definitions | `plan/current/slo-definitions.md` | A deployed runtime service has a latency, availability, or throughput target in the design |
| Cost model | `plan/current/cost-model.md` | New or materially changed compute, storage, or third-party spend |
| Component manifest | `src/{component-id}/component.yml` | One per component. Populate purpose, scope, risk, and contract from the requirements set. Never modify the pre-seeded `stack` section. `purpose.notResponsibleFor` is mandatory. Leave `contract.consumedBy` empty |
| Data contract | `src/{component-id}/docs/data-contract.md` | One per data-owning component |

## Story mapping pass

Run this pass before you write any requirement file. Write `plan/current/story-map.md` from `ravintio-zero/templates/story-map.template.md`.

1. List the activities a user performs in the feature, then the steps under each.
2. Match each step to a user story in the brief. Put `REQ-nnn` in its Requirement cell.
3. Record a step with no story as a gap.

Resolve each gap by this rule:

- If the brief states or implies the step, add a new story and a new requirement. Write `gap: added as US-nnn`.
- Otherwise add the step to the out-of-scope list in `scope.md`. Write `gap: out of scope`.

In a gated run, ask the human about a gap of the second kind. Ask one question at a time.

## Test impact scan

Run this scan before you write the execution plan. For each cause below that the run triggers, grep `ravintio-zero/tests/`. List every match under `## Test impact` in the execution plan, in the unit that edits the file.

- **Skill count:** the run adds or removes a skill. Grep for `skills/` with `wc -l`.
- **Skill-text budget:** the run edits any `SKILL.md`. Grep for the line cap.
- **Size cap:** the run edits a skill that a cap test measures, such as the orchestrator. Grep for the skill name and `-le`.
- **Backlog entry id:** the run pulls in an entry. Grep for the entry id.

If a grep matches nothing, write `none found` in the row.

## Requirements rules

- Derive requirements directly from user stories in the brief. Do not invent requirements not stated or implied.
- One file per story at `plan/current/requirements/{req-id}-{slug}.md`, from `ravintio-zero/templates/requirement.template.md`. No monolithic list in the execution plan.
- Write each acceptance criterion as a checkbox line `- [ ] AC-{n}: {short name}` with indented `Given`, `When`, and `Then` bullets. `And` and `But` continue the step above. The limit of three criteria counts checkbox lines, not steps.
- Non-functional requirements state specific, measurable targets. No vague qualifiers. If the design defers an NFR, note it in scope and do not fabricate a target.
- The OpenAPI spec covers every endpoint implied by the requirements. No more, no less. Use OpenAPI 3.1 with JSON Schema bodies. Produce it early, since everything downstream implements against it.
- Never invent domain language. If a concept has no clear name, flag it for the human. In a retrofit, include terms the codebase already uses.
- Every risk has a category (technical, operational, security, compliance), a likelihood, and an impact. No generic risks.
- Deferred scope items note what is blocked until they resolve.
- Documented assumptions are allowed for genuinely minor gaps. Record each in the risk register at likelihood medium. Do not assume away material ambiguity. Report it back instead.

## ADR rules

A decision needs an ADR when it meets any of these criteria:

- **Costly to reverse** - database engine, ORM, auth strategy.
- **Crosses components** - sync vs async communication, shared types, event schema.
- **Constrains future work** - deployment topology, provider lock-in, data partitioning.
- **Deviates from the declared stack** - any library or compute model not in the design. A library or service that is not on the approved list also takes the dependency exception stop. The list is the `Approved dependencies` field of `design.md` in a gated run and the `## Dependencies` table of `initiative.md` in an initiative step. This applies in every run mode.
- **Security trade-off** - session storage, token expiry, CORS configuration.
- **Data ownership assignment** - every data ownership mapping gets an ADR.

No ADR for decisions already mandated by the requirements, direct consequences of the stack declaration, or single-component implementation details. Write one ADR recording the stack choice itself, referencing the design.

- Follow `ravintio-zero/templates/adr.template.md`. Be specific. Vague ADRs are useless.
- Number sequentially from ADR-001.
- Consequences include at least one positive and one negative.
- If a decision supersedes a prior ADR, mark the prior one `Superseded by ADR-{NNN}` and reference it in the new ADR's context.

## Gate

The plan phase ends at one human gate. Before presenting the gate summary:

1. Run `node ravintio-zero/scripts/consistency-check.mjs` over the artifact set.
2. Fix what it flags and re-run until clean. This mechanical check is mandatory.

Then present the artifact set summary and stop for human confirmation.

## Concurrency plan

Write a `## Concurrency plan` section in each execution plan, per `ravintio-zero/templates/execution-plan.template.md`. Rewrite it in any re-plan after a reopened phase.

- Place two units with no dependency and no shared write target in one batch.
- Give a `Sequential reason` for each unit that runs alone in its batch.
- Name only units from earlier batches in `Depends on`.

The consistency check validates the section (check 8).

## Parallelism

Dispatch subagents per `ravintio-zero/standards/agent-dispatch-standards.md`.

| MUST parallelise | Cannot parallelise |
|---|---|
| Requirement files for independent stories | Requirements that reference each other |
| Scope, risk register, and domain glossary | Execution plan summary before requirements are drafted |
| ADRs for independent decisions | An ADR that builds on another ADR's decision |
| Component manifest drafts | Data contract and data-ownership ADRs before ownership is settled |

### Fast batch

When `plan/.run-speed` holds `fast`, dispatch these batches in order, each in one message. Within a batch, every unit writes its own files.

1. After the story map pass: one unit per requirement file for an independent story, plus one unit for scope, risk register, and domain glossary.
2. After the requirements: one unit per ADR for an independent decision, plus one unit per component manifest draft.
3. Inline: the execution plan, then the consistency check and the gate.

At `standard`, the table above applies.

Out-of-scope discoveries by a dispatched subagent go straight to `plan/backlog/` per the dispatch standard's filing clause.

## Waved features

When the confirmed design groups features into waves:

- Produce artifacts for the current wave only. Later waves may change.
- Suffix wave artifacts, for example `execution-plan-wave-2.md`. Reference prior-wave manifests and contracts rather than re-specifying them.
- The glossary and risk register are cumulative. Add entries each wave and never remove prior ones. Risks remain unless explicitly mitigated.

## Commit cadence

Commit after every meaningful artifact write. Do not batch commits to the phase gate.
