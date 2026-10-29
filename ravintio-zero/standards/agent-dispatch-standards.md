---
title: "Agent Dispatch Standards"
version: "1.0.0"
---
# Agent Dispatch Standards

Canonical home for model tier selection and parallelism/dispatch mechanics, shared by the orchestrator and every phase skill that spawns subagents.

---

## Model Tier Decision Table

**Consult this table before spawning every subagent.** Resolve the tier to a concrete model name for the active tool, then pass it explicitly.

| Task type | Tier | Rationale |
|-----------|------|-----------|
| Codebase discovery (grep, find, ls, file listing) | Cheaper | No synthesis required |
| Single-file read with no synthesis | Cheaper | Mechanical retrieval |
| Formatting / spelling / lint checks | Cheaper | Pattern matching, no reasoning |
| Validation (lint, typecheck, test runner) | Cheaper | Tool execution, not reasoning |
| Web research: fetching a single known reference doc | Cheaper | Retrieval, minimal synthesis |
| Documentation writing (no novel decisions) | Cheaper | Structured output from known inputs |
| Web research with synthesis across multiple sources | Primary | Reasoning across conflicting sources |
| Code generation | Primary | Multi-file reasoning, correctness required |
| Security review | Primary | Adversarial reasoning, high-stakes |
| Architecture decisions (ADR writing) | Primary | Consequential, requires judgement |
| Requirements writing (spec) | Primary | Ambiguity resolution, domain reasoning |
| Discovery coaching | Primary | Dialogue, gap assessment |
| Build assessment (ship phase) | Cheaper | Read-only summarisation from a structured log |

**Tier-to-model mapping by tool** (the Agent tool's `model` values are aliases, so they track new releases):

| Tool | Primary tier | Cheaper tier |
|------|-------------|-------------|
| Claude Code | `sonnet` | `haiku` |

**How to apply:** Before calling `Agent(...)`, look up the task in the table. Pass `model: {resolved model name}` as a parameter. An Agent call without `model` inherits the parent's model, so a cheaper-tier task would run on the parent's tier. Every Agent call passes `model` explicitly. Record the tier in the build log for the ship phase's build assessment.

---

## WebFetch of a reference page

Run a `WebFetch` of a full reference page in a subagent on `sonnet` or `haiku`. The page then stays out of the main session, so later turns do not re-read it.

1. Name the extract the parent needs in the dispatch prompt.
2. The dispatch passes `model` explicitly, as the tier table requires.
3. The subagent returns only that extract, not the page.

A small page that the parent needs in full may run in the main session.

---

## Parallelism Rules

**Default posture: parallel.** Sequential dispatch requires an explicit dependency justification. **Dependency test:** can task B start before task A's output is available? If you cannot state why it must wait, dispatch both in parallel (single message, multiple Agent tool calls).

### MUST parallelise

| Pattern | Example |
|---------|---------|
| Multiple independent codebase searches | Grepping for hook files + scanning skill dirs simultaneously |
| Web research across independent sources | Two vendors' hook documentation, same question, different sources |
| Independent document reads | Reading 3 skill files that do not reference each other |
| Background test runner while writing docs | Run `run-tests.sh` in background while ravintio-implement produces doc output |
| Multi-component security reviews (no shared state) | Reviewing component A and component B in parallel |
| Independent requirement files (no cross-references) | Writing req-001 through req-008 in a single parallel batch |
| Independent new test files closing a coverage gap | 2+ new test files, each testing independent, non-cross-referencing sections, dispatched in a single parallel batch instead of written one after another |
| Independent living-doc edits (no shared content) | 2+ living docs (e.g. component-registry.md, decisions-index.md) that don't read each other's new content, edited in a single parallel batch instead of serially |

### Cannot parallelise

| Pattern | Reason |
|---------|--------|
| Phase N work before Phase N-1 artifacts exist | Hard phase dependency |
| ADR writing before requirements are complete | ADR content depends on the requirements output |
| Implementation before the plan gate passes | ADRs may constrain implementation choices |
| Build assessment before the ship-phase archive is confirmed | Report needs the archive path |
| Tasks where B reads A's output | Sequential by definition |

**Record in build log:** After each phase, record the parallel task batch count. If it is 0 for a phase where parallelism was possible, the ship phase's efficiency observation will flag it.

---

## Concurrency plan

Dispatch follows the batches in the `## Concurrency plan` of `plan/current/execution-plan.md`.

- Two units with no dependency and no shared write target share a batch.
- A unit alone in its batch gives its reason in the `Sequential reason` column.
- A departure from the plan's batches is recorded in the build log with its reason.
- Check 8 of `consistency-check.mjs` validates the table.

---

## Improvement loop

After ravintio-refactor confirms all-suite GREEN, ravintio-implement runs up to 2 cycles per requirement. Each cycle asks whether a simpler or cleaner solution meets the same tests.

1. Dispatch a reviewer in a fresh context on the primary tier. Pass it the requirement, the test file, and the implementation files. Do not pass the transcript of earlier dispatches. The reviewer edits nothing.
2. The reviewer returns one finding worth making, or the text `no change worth making`. It reports only a change that simplifies the code, removes duplication, or picks a cleaner design. It skips style preferences and any change that alters behaviour.
3. If the reviewer returns `no change worth making`, append the early stop marker. The loop stops early for that requirement.
4. If the reviewer returns a finding, dispatch ravintio-refactor in improvement mode with that finding, then run the full suite.
5. If the suite fails, ravintio-refactor reverts the change. The requirement stays GREEN, and the cycle records `suite fail, reverted`.
6. Append the cycle marker to the build log before the next dispatch.

The marker forms are in `ravintio-zero/standards/workflow-governance-standards.md`. On resume, count the `Improve:` markers for the requirement in the build log and run only the cycles that remain.

---

## Fast batches

The run speed is in `plan/.run-speed`. It holds `fast` or `standard`. A missing or unknown value counts as `standard`. See the orchestrator skill.

At `fast`, a phase dispatches every unit of its fast batch in one message. It makes one `Agent` call per unit and passes `model` on each.

- Units in one batch write disjoint files. A dependency manifest or lock file counts as shared, so at most one unit in a batch may add a dependency.
- Units share one working tree, so they commit one at a time. Each unit stages its own files by path, never with `git add -A` or `git add .`. If a commit meets `.git/index.lock`, wait and retry it.
- Never run `git stash`, `git checkout`, or `git reset` in a subagent during a batch. A stash takes the uncommitted work of every other subagent in the tree.
- The Cannot parallelise table still applies.
- Phases run in order. No unit of phase N+1 starts before phase N ends.
- Gates, exception stops, and progress markers stay as they are. Write one `In progress:` line per unit in a single commit before the batch.
- If one unit takes an exception stop, start no further unit. Let running units finish and commit their work, then take the stop.
- A unit with fewer than two independent pieces stays inline.

At `standard`, each phase keeps the parallelism rules above. Each phase skill lists its fast batch under `### Fast batch`. The build log records the agent count and wall-clock time for each phase.

---

## Agent Dispatch Template

Agent spawning is level-2 parallelism (the Agent tool for independent sub-tasks that each need their own tool access and context); level-1 (multiple native tool calls in one message) is covered by Parallelism Rules above. Spawn when a task is self-contained enough to brief to a colleague in one paragraph; stay inline when it needs ongoing dialogue, shared mutable state, or is too small to justify the overhead.

**Concrete parallel dispatch skeleton** (send both `Agent()` calls in a single message so they execute concurrently):

```
Agent({ description: "Implement REQ-001: {one-liner}", subagent_type: "general-purpose", model: "haiku",
  prompt: "Requirement: plan/current/requirements/req-001-{slug}.md. ADR: plan/current/adr/ADR-00N-{slug}.md. Stack: {constraint}. Task: {what to build}. If you discover an out-of-scope bug/gap, file it at plan/backlog/{backlog-id-1}-{slug}/entry.md per templates/backlog-entry.template.md; do not report it back for me to relay. Never run git stash, git checkout, or git reset: a stash takes the uncommitted work of every other subagent. Confirm: files modified, what changed." })

Agent({ description: "Implement REQ-002: {one-liner}", subagent_type: "general-purpose", model: "haiku",
  prompt: "Requirement: plan/current/requirements/req-002-{slug}.md. ADR: plan/current/adr/ADR-00N-{slug}.md. Stack: {constraint}. Task: {what to build}. If you discover an out-of-scope bug/gap, file it at plan/backlog/{backlog-id-2}-{slug}/entry.md per templates/backlog-entry.template.md; do not report it back for me to relay. Never run git stash, git checkout, or git reset: a stash takes the uncommitted work of every other subagent. Confirm: files modified, what changed." })
```

**Self-contained prompt rule:** include the requirement file path, relevant ADR paths, stack declaration or relevant constraint, the backlog ID to use if filing an out-of-scope discovery, and what "done" looks like. Do NOT rely on shared conversation history: the spawned agent has no memory of this session.

**Model tier for spawned agents:** see the Model Tier Decision Table above.

**Out-of-scope discovery filing:** if a dispatched subagent discovers an out-of-scope bug or gap while doing its task, it MUST file `plan/backlog/{id}-{slug}/entry.md` directly, per `templates/backlog-entry.template.md`, with `Deferral source: discovered mid-flight`, `Source feature` set to the active feature ID, and `Source phase` set to the phase active at discovery. It must NOT report the discovery back for the dispatching agent to relay through a host-tool side channel (e.g. a task-spawning tool), and must NOT silently drop it.

The **dispatching agent** (orchestrator or phase skill placing the `Agent()` call) pre-computes the next available backlog ID before dispatch by reserving it with `node ravintio-zero/scripts/reserve-id.mjs`, which takes it from the counter file `plan/backlog/.next-id`, and passes it explicitly in the subagent's prompt as the ID to use if a discovery needs filing. Subagent self-lookup of `plan/backlog/` at file-time is rejected: picked-up entries are deleted from `plan/backlog/` once folded into a design, so a subagent scanning only that directory would systematically undercount the true high-water mark and risk reusing a retired ID.

When dispatching multiple subagents in a single parallel batch, each MUST receive a distinct pre-assigned backlog ID (or a reserved contiguous block, one per subagent); no two subagents may independently file under the same ID.

---

## Progress Markers and Interrupted Units

A unit is one piece of dispatched work: a TDD subagent in P2, a self-correct cycle in P3, or any subagent dispatched under this standard. Progress markers let a fresh session tell which unit a stop interrupted. The build log alone then says where to restart.

### Marking a unit

1. Before the unit starts, append this line to `plan/current/build-log.md` and commit it before the unit starts:

   ```
   - In progress: {unit} ({ISO-8601 timestamp})
   ```

   `{unit}` names the requirement and the stage, for example `REQ-001 test-writer` or `P3 cycle 2`.

2. When the unit finishes, append this line in the same commit as the unit's work:

   ```
   - Done: {unit} ({ISO-8601 timestamp})
   ```

In a parallel batch, write one `In progress:` line per unit in a single commit before the batch starts. Each unit's `Done:` line lands with that unit's work.

### Resuming an interrupted unit

On resume, read the build log. An `In progress:` line with no later matching `Done:` line marks an interrupted unit. For each one:

1. If the working tree has uncommitted changes, stash them. Never discard them.

   ```bash
   git stash push --include-untracked -m "interrupted {unit}"
   ```

2. Rerun the unit from its start.
3. Append this line and commit it with the rerun's first commit:

   ```
   - Resumed after interruption: {unit} rerun, uncommitted changes in stash "interrupted {unit}"
   ```

   If the tree was clean, end the line with `no uncommitted changes` instead.

Never commit uncommitted files that an interrupted unit left behind without rerunning the unit. A stop can cut a file off partway through, and nothing records whether it finished. The stash keeps the files for the human to inspect.

The initiative driver reads only `Blocked:` and `Resolved:` lines. Progress markers never stop it.
