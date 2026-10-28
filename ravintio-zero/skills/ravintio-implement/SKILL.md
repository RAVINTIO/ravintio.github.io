---
name: ravintio-implement
description: Implements requirements with tests and documentation landing together through the TDD loop. Invoked during the implement phase.
---

# RAVINTIO - implement

> You implement the system the plan describes. Code, tests, and documentation land together in this phase. You build against the contract, not beyond it.

**Prefix.** Begin every reply with `P2 Implement:`, in the form `{prefix} {Status}: {one-liner}`, as in `P2 Implement: Starting: {one-liner}`.

**Pack files.** Read each of these from the pack folder before the step that uses it:

- `ravintio-zero/templates/component.template.yml`
- `ravintio-zero/templates/data-contract.template.md`
- `ravintio-zero/standards/code-quality-standards.md`
- `ravintio-zero/standards/testing-standards.md`
- `ravintio-zero/standards/build-target-standards.md`

## Input

Precision reading protocol: scope your context by navigating precisely. Never read the entire `plan/` directory unconditionally.

- Component manifest at `src/{component-id}/component.yml`. Read the frontmatter first to decide whether the body is needed.
- Execution plan at `plan/current/execution-plan.md` for the architecture overview.
- Requirements at `plan/current/requirements/*.md`. Read only the requirement file you are actively implementing.
- OpenAPI specification at `plan/current/openapi-spec.yaml` (if applicable).
- Domain glossary at `plan/current/domain-glossary.md`. Use its terms in code, comments, file names, and variable names.
- Data contracts at `src/{component-id}/docs/data-contract.md` (if they exist).

**Domain context for existing components.** Before changing an existing component, read its `docs/` set: purpose, interface contract, dependencies, data contract, quirks, and tech debt. Assess the blast radius of the change before writing any code.

Check whether capability skills exist for the declared stack and load them alongside this skill. Do not invent a skill reference that does not exist.

## Build target

When `plan/current/design.md` declares `Build target: docker`:

- Never check host-installed runtimes or tools. Do not run `node`, `python`, `go`, `dotnet`, or equivalents on the host.
- Never fail or warn because a runtime is absent on the host. It is expected to be absent.
- Scaffold Dockerfile-first. Generate the `Dockerfile` and `docker-compose.yml` before any source code.
- All validation runs via `docker build` and `docker run`, never the host toolchain.

When the build target is local, use the host toolchain.

## Outputs

For each component at `src/{component-id}/`: application code, shared types and validation schemas, unit tests for pure functions, integration tests for endpoints, contract tests for cross-component interfaces, and declared infrastructure. Documentation for the component lands in the same phase. Code and docs are never committed separately.

Build multiple components in dependency order: shared packages, then data owners, then consumers. Each component is finished (code, tests, docs) before the next starts. Halt and escalate on a circular dependency.

Before writing any dependency manifest, check `ravintio-overrides/library-standards/{language}/prefer-avoid.md`, then the pack's `ravintio-zero/standards/library-standards/` lists. Substitute preferred alternatives for avoided libraries. If an avoided library has no alternative, record the exception in `src/{component-id}/docs/quirks.md` and escalate. Skip the audit when the lists are stubs. Follow `ravintio-zero/standards/library-standards/_version-policy.md` for version pinning.

Before adding any library or service, check that it is on the approved list. The list is the `Approved dependencies` field of `design.md` in a gated run and the `## Dependencies` table of `initiative.md` in an initiative step. If it is not on the list, take the dependency exception stop: `{prefix} Blocked: new dependency {name} is not on the approved list. Approve it or choose an approved alternative.` This applies in every run mode.

## TDD inner loop

For each functional requirement, orchestrate three subagents in sequence. This is the mandatory implementation discipline.

```
for each requirement:
  attempt = 0
  repeat:
    attempt++
    1. dispatch ravintio-test-writer  -> wait for RED (non-zero exit)
    2. dispatch ravintio-implementer  -> wait for GREEN (zero exit)
    if GREEN:
      3. dispatch ravintio-refactor   -> wait for all-suite GREEN
      4. run the improvement loop     -> up to 2 cycles
      break
    else if attempt >= 5:
      ESCALATE to the human. Do not proceed to the next requirement.
```

Pass each dispatch the `model` from that skill's own `recommended_model` field. If a haiku unit fails twice, retry that unit on `sonnet`. The two haiku failures count toward the five attempts, and the five-attempt escalation is unchanged.

After 5 failed attempts on one requirement, stop in both run modes with `P2 Implement: Blocked: {requirement} still fails after 5 attempts. Review the escalation and choose the next step.` Then report: the requirement ID, the test file, what each attempt tried and why it stayed RED, your root-cause assessment, and a recommended action. Wait for human direction.

For each attempt on a requirement after the first, append `Rework: REQ-{nnn}: {reason} ({ISO-8601 timestamp})` to the build log. The marker forms are in `ravintio-zero/standards/workflow-governance-standards.md`.

Every requirement must have a mapped test whose name includes the requirement ID (for example `describe('req-001-auth: login flow', ...)`). Write E2E tests for critical user flows named in the acceptance criteria. Write to disk after each subagent, and mark each one per "Progress Markers and Interrupted Units" in `ravintio-zero/standards/agent-dispatch-standards.md`. Do not accumulate work in memory across requirements.

## Improvement loop

After refactor confirms all-suite GREEN, run up to 2 cycles per requirement, as `## Improvement loop` in `ravintio-zero/standards/agent-dispatch-standards.md` describes. Each cycle dispatches a fresh-context reviewer, then ravintio-refactor in improvement mode with its finding, and appends an `Improve:` marker. The loop stops early on `no change worth making`.

## Rules

- **One question at a time** when you need human input.
- **Implement against the requirements.** The OpenAPI spec defines the contract. Do not add or remove endpoints. Follow the ADRs. Flag a wrong ADR rather than overriding it silently. Do not introduce technology the stack does not declare.
- **Schema changes.** Write a migration proposal at `src/{component-id}/docs/migrations/proposed-{desc}.md` and STOP for human approval in both run modes: `P2 Implement: Blocked: schema change proposed at {path}. Approve or reject the migration proposal.` Never modify a schema directly. Destructive operations (drop, rename) always stop. This is a hard limit. In an initiative step, a chart-approved additive change does not stop (see `ravintio-zero/standards/roadmap-standards.md`).
- **Data ownership.** Never write to data owned by another component. Create a data contract before writing any schema code for a component that owns data.
- **Rollbacks are human-initiated, never automatic.** No agent rolls back a deployment, migration, or artifact on its own.
- **Deviation.** If implementation deviates from the spec, plan, or design, update the affected `plan/` or `docs/` artifacts in the same commit. Record the deviation in `docs/quirks.md` and the component manifest, or stop and ask when continuing would be wasteful.
- **Quirks and tech debt** go to `src/{component-id}/docs/quirks.md` and `tech-debt.md`, mirrored in the `quality` section of `component.yml`. Never silently work around them.
- **Component manifest close-out.** After the build, update `component.yml`: `data`, `quality`, `pipeline`, `metadata`, and `version`.

## Documentation

Docs are produced in this phase, alongside the code they describe.

Per-component artifacts at `src/{component-id}/docs/`:

| Artifact | File |
|---|---|
| Component purpose | `purpose.md` |
| Interface contract | `interface-contract.md` |
| Dependencies | `dependencies.md` |
| Data contract (if it owns data) | `data-contract.md` |
| Risk and scope | `risk.md`, `scope.md` |
| Quirks and tech debt (if any) | `quirks.md`, `tech-debt.md` |
| Test coverage summary | `test-coverage.md` |

Living docs at `docs/` describe the current system state. Update them, do not recreate them, and keep them present-tense. History goes to change records only.

| Living doc | Path | Condition |
|---|---|---|
| Component registry | `docs/component-registry.md` | Always |
| Dependency graph | `docs/dependency-graph.md` | Always |
| Architecture overview | `docs/architecture-overview.md` | Always |
| Decisions index | `docs/decisions-index.md` | Always |
| API index | `docs/api-index.md` | When a component exposes an API |

Stamp each living doc with `Last updated: {feature-id}`. Read the matching template before writing a living doc for the first time. If `docs/` is absent, fail with a clear message and do not proceed.

Docs rules:

- Account for every artifact. Produce what is missing, or note a legitimate absence explicitly (for example no data contract when `ownsData: false`).
- Keep cross-references consistent: registry links to each purpose doc, and the dependency graph matches the per-component dependency files.
- Check for drift between spec and implementation: endpoints, glossary terms, component boundaries, data ownership, ADR compliance, and dependency direction. Flag drift, do not silently fix it.
- Write the change record at `plan/changelog/{feature-id}-{date}.md` from `ravintio-zero/templates/iteration-log.template.md`.
- File each deferred item and tech debt row as its own `plan/backlog/{id}-{slug}/entry.md` per `ravintio-zero/templates/backlog-entry.template.md`.

## Parallel dispatch

Independent requirements MUST be dispatched in parallel per `ravintio-zero/standards/agent-dispatch-standards.md`. Before writing any code:

1. List all requirements for the phase.
2. Take the batches from the `## Concurrency plan` in `plan/current/execution-plan.md`. Do not map dependencies afresh.
3. Dispatch each batch in a single parallel message, in batch order. Record a departure from the batches in the build log with its reason.
4. Record the batch count in the build log. If nothing can be parallelised, state the dependency reason there.

Per-component docs for independent components also parallelise. The registry and dependency graph wait until all component docs exist. If a dispatched subagent finds an out-of-scope bug or gap, it files a `plan/backlog/` entry directly per the dispatch standards.

### Fast batch

When `plan/.run-speed` holds `fast`, dispatch these batches in order, each in one message. Within a batch, every unit writes its own files.

1. One TDD track per leaf requirement whose files no other track writes. Each track runs test-writer, implementer, refactor, and the improvement loop in sequence.
2. One TDD track per dependent requirement, after its dependencies finish.
3. One unit per independent living doc and per-component doc set, while the full test suite runs in the background.
4. Inline: the registry and dependency graph, then the component manifest close-out.

At `standard`, the steps above apply. The five-attempt escalation is unchanged.

## Commit cadence

Commit after every requirement's completed TDD cycle at minimum, and after every meaningful artifact write. Never batch changes to the phase gate. Each commit carries the code and the docs that describe it together.
