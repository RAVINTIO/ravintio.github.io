# Pipeline Reference

> Deep reference for RAVINTIO pipeline mechanics. For first-time setup, start with [getting-started.md](getting-started.md).

---

## One Route

Every change is a feature change. It runs the five-phase feature pipeline: discovery, plan, implement, validate and accept, ship. A small change is a small run: fewer requirements, shorter artifacts, the same gates. There is no separate route for trivial fixes or targeted changes.

The five phases use these identifiers throughout the pipeline's artifacts and prose: `discovery`, `plan`, `implement`, `validate-and-accept`, `ship`.

---

## Phase Indicators

Every agent response begins with a phase prefix. You always know where you are.

| Prefix | Phase | What the agent is doing |
|--------|-------|-------------------------|
| `P0 Discovery:` | P0 Discovery | Assessing the brief, asking gap questions, confirming scope, version, and adoption mode |
| `P1 Plan:` | P1 Plan | Writing requirements, scope, glossary, risk register, and ADRs behind one confirmation gate |
| `P2 Implement:` | P2 Implement | Generating code, tests, and documentation together |
| `P3 Validate:` | P3 Validate and Accept | Running CI checks, self-correcting, security review, human acceptance |
| `P4 Ship:` | P4 Ship | Changelog, archive, build assessment, PR |

Messages shorten P3 to "Validate". Skills and the build log keep the full name "Validate and Accept".

Status messages use one form: `{prefix} {Status}: {one-liner}`. The status is Starting, Resuming, Complete, Blocked, or Skipped.

- Entering a phase: `P1 Plan: Starting: {one-liner}`
- Resuming: `P1 Plan: Resuming: {what was in progress, what is next}`
- Completing: `P1 Plan: Complete: {one-liner summary}`
- Blocked: `P0 Discovery: Blocked: {specific gap}`
- Skipped: `P3 Validate: Skipped: {reason}`

Initiative stages use five more prefixes. They use the same `{prefix} {Status}: {one-liner}` form.

| Prefix | Stage | What the agent is doing |
|--------|-------|-------------------------|
| `I-A Chart:` | Chart | Planning an initiative with the human and taking their confirmation |
| `I-B Activate:` | Activate | Cutting the initiative branch, writing the active initiative, and offering the driver |
| `I-C Run:` | Run | Running one initiative step through P0 to P4 |
| `I-D Advance:` | Advance | Merging the step PR into the initiative branch and tagging it |
| `I-E Delivery:` | Delivery | Archiving the initiative and raising the initiative PR to `main` |

- Starting a step: `I-C Run: Starting: {step}`
- Blocked: `I-B Activate: Blocked: {failed check}`

I-A to I-E are stage letters, not phase numbers. The pipeline still has exactly five phases, P0 to P4.

If you see a `Resuming` message at the start of a session, the orchestrator detected existing artifacts in `plan/current/` and is continuing where it left off.

---

## Skills

Twelve skills drive the pipeline.

| Skill | Role |
|-------|------|
| `ravintio-orchestrator` | Owns discovery and routing. Coordinates the run end to end |
| `ravintio-plan` | Plan phase: requirements, scope, risk register, glossary, ADRs |
| `ravintio-implement` | Implement phase: dispatches the TDD trio per requirement and writes the documentation |
| `ravintio-validate-and-accept` | Validate-and-accept phase: CI checks, security review, acceptance gate or PR evidence |
| `ravintio-ship` | Ship phase: changelog, archive, build assessment, tag, PR |
| `ravintio-test-writer` | TDD red: writes one failing test per requirement and confirms RED |
| `ravintio-implementer` | TDD green: writes the minimum code to make that test pass |
| `ravintio-refactor` | TDD refactor: improves quality while all tests stay passing |
| `ravintio-loop-runner` | Canonical loop mechanics: state files, stop rules, escalation format |
| `ravintio-optimise-agent` | Reviews skills for superfluous content, one suggestion at a time |
| `ravintio-migrator` | Applies pending pack migrations interactively |
| `ravintio-refresh-setup` | Re-runs setup with the flags currently in effect |
| `ravintio-file-backlog` | Files one uncommitted backlog entry in another repo |
| `ravintio-postmortem` | Writes one blameless postmortem per failed CI run or Blocked stop, and files its actions |
| `ravintio-retrospective` | Writes one blameless retrospective per shipped run and per delivered initiative, and files its changes |
| `ravintio-initiative` | Coordinates an initiative from chart to delivery in the human's session, reports progress, and never runs a step |

The TDD trio (`ravintio-test-writer`, `ravintio-implementer`, `ravintio-refactor`) is dispatched by `ravintio-implement`, once per requirement. After GREEN and refactor, the improvement loop runs up to 2 cycles per requirement and records an `Improve:` marker for each.

---

## Phase Confirmation Gates

At the end of discovery, the orchestrator asks:

```
How should the agent run P1 to P4?

  [1] Gated: the agent stops for you at the end of each phase
  [2] Autonomous: the agent runs to a raised PR and stops only for escalations
```

It writes `gated` or `autonomous` to `plan/.run-mode` and logs the choice in the build log.

- **Gated**: the orchestrator stops and presents a summary at the plan, implement, acceptance, and ship gates. The ship gate comes before the PR.
- **Autonomous**: the orchestrator stops at none of those gates. Validate and accept puts its evidence in the PR description. Ship raises the PR and ends with `P4 Ship: Complete: PR #{n} ready for your review`.

Both modes stop with a `Blocked:` message on five escalations:

- A requirement or check still fails after 5 attempts.
- Implement needs a schema change. In an initiative step, a change that matches a chart-approved additive row does not stop.
- The security review finds an unmitigated critical or high issue.
- A push or `gh pr create` fails.
- A possible credential appears in a file the run will commit, or in the PR body.

Each stop adds a `Blocked:` line to the build log, and the human's answer adds a `Resolved:` line. A resumed run does not pass an unresolved stop.

The phase skills are the single source for gate behaviour. Merging the PR is human-only in every mode.

### Run speed

After the run mode, the orchestrator asks for a run speed and writes `standard` or `fast` to `plan/.run-speed`. A missing or unknown value counts as `standard`. An initiative step takes the speed from the initiative's `**Speed:**` field.

- **Standard**: each phase applies its own parallelism rules.
- **Fast**: each phase dispatches the units in its `### Fast batch` list, each batch in one message.

Phases run in order at either speed, and every gate and escalation stays in place. Each build-log phase block records its `End` and `Wall clock` time, and the build report lists them with the agent count.

---

## Ship Phase

Ship is the terminal phase. It runs three steps in order.

1. **Archive.** The changelog entry is written to `plan/changelog/{feature-id}-{YYYY-MM-DD}.md`, then `plan/current/` is archived to `plan/_archive/{feature-id}-{date}/` and cleared. The orchestrator sentinel is deleted last, after the archive is confirmed complete.
2. **Build assessment.** An assessment sub-agent reads the archived `build-log.md` and produces a structured efficiency report at `plan/_archive/{feature-id}-{date}/build-report.md`.
3. **Tag and PR.** The agent reads the version from `component.yml`, checks the PR body for attribution lines, then raises the PR. It creates no tag. After the human merges, the CI `release-tag` job tags the merge commit on `main` with `v{version}`. In a gated run, it first asks the human whether to push and raise the PR or output a PR description for manual use. If `local-git-only` is active in `ravintio-overrides/instructions/`, the agent skips the prompt and outputs a PR description directly.
   - **Initiative step.** When `plan/current-initiative/initiative.md` has `status: active`, the order differs. The agent raises the PR with `--base initiative/{id}-{slug}`, waits for green CI, squash-merges, fetches, then tags the squash commit and pushes the tag. After the last step, I-E Delivery archives the initiative and raises one PR to `main` that asks for a merge commit. The agent never merges that PR. See the ship skill's Initiative steps section.

### Build Log

From discovery onwards, the orchestrator maintains `plan/current/build-log.md`, a working file tracking per-phase build metrics. It is created from `ravintio-zero/templates/build-log.template.md` at discovery and appended at each phase boundary. If a session is interrupted and resumed, the orchestrator appends rather than overwrites. Each dispatched unit also logs `In progress:` and `Done:` lines, so a resumed session reruns an interrupted unit. See "Progress Markers and Interrupted Units" in `ravintio-zero/standards/agent-dispatch-standards.md`.

The build log records per phase: model tier used, skills loaded, agents spawned, MCP tool calls, parallel task batch count.

### What the build assessment checks

The assessment is adversarial, not a summary. It asks:

- **Model routing**: which phases used the primary tier when cheaper-tier tasks were eligible?
- **Parallelism**: which phases ran tasks sequentially that should have been parallel?
- **Phase gates**: were human confirmation gates honoured, or did the pipeline run autonomously without authorisation?
- **Self-corrections**: how many occurred, and were they avoidable?
- **Build log integrity**: are all phases represented with populated fields?

### Workflow governance

The build report also carries a `## Workflow governance` section from `scripts/workflow-metrics.mjs`. The script counts four marker lines in the archived build log and loop-state files:

- `Rework:` lines per requirement
- `Blocked:` stops
- `Requirement change:` lines
- `Gate revised:` lines

It compares each count against a threshold in `standards/workflow-governance-standards.md`. Ship copies the section into the PR description. A breach never stops ship.

---

## Model Tier Routing

The orchestrator consults the **Model Tier Decision Table** before spawning every subagent, then passes the resolved model explicitly.

| Task type | Tier |
|-----------|------|
| Codebase discovery (grep, find, ls) | Cheaper |
| Single-file read with no synthesis | Cheaper |
| Formatting / spelling / lint checks | Cheaper |
| Validation (lint, typecheck, test runner) | Cheaper |
| Fetching a single known reference doc | Cheaper |
| Documentation writing (no novel decisions) | Cheaper |
| Build assessment | Cheaper |
| Web research with synthesis | Primary |
| Code generation | Primary |
| Security review | Primary |
| ADR writing | Primary |
| Spec / requirements writing | Primary |
| Discovery coaching | Primary |

Tier-to-model mapping for Claude Code: primary is `claude-sonnet-4-6`, cheaper is `claude-haiku-4-5`.

---

## Enforcement Hooks

Setup wires the enforcement hooks into `.claude/settings.json` on every install. All of them are Node `.mjs` scripts under `hooks/enforcement/`.

| Hook | Trigger | What it does |
|------|---------|--------------|
| `gate-write` | PreToolUse (Write, Edit) | Gates every in-project path that is not always permitted. Blocks the write unless `plan/current/design.md` exists and the target path matches a declared component. Writes to `plan/current/` also need the `plan/.orchestrator-active` sentinel. Targets outside the project pass |
| `ratchet-check` | PreToolUse (Write, Edit) | While a loop or reversal is active, blocks edits that weaken acceptance criteria (checkbox and Gherkin step lines) or in-scope lines in `plan/current/`. The block message cuts each removed line to 200 characters |
| `em-dash-guard` | PreToolUse (Write, Edit) | Rejects U+2014 in scoped prose paths |
| `check-design` | UserPromptSubmit | Injects active component scope from `design.md`, or a hard STOP when no brief or sentinel exists |
| `check-orchestrator-presence` | UserPromptSubmit | Injects a reminder banner while a pipeline is active. Hard-blocks under strict mode |
| `auto-trigger-orchestrator` | UserPromptSubmit | Loads the orchestrator skill at session start when no pipeline is active yet |
| `check-reply-prefix` | Stop | Warns when a reply in an active run lacks a valid prefix, and logs each miss. Never blocks |

A blocking hook exits 2 with a human-readable message. Every hook fails open on an unexpected error, so a broken hook never stops a session.

---

## Git Guardrails

The setup script activates RAVINTIO's **Progressive Guardrail System**, a three-tier enforcement model that protects `main` without blocking atomic commits.

| Tier | When | What happens |
|------|------|--------------|
| **1: Advisory pre-commit** | Every local commit | Checks whether code was staged without docs. Prints a warning if so. Commit **succeeds** regardless. |
| **2: Branch pre-push** | Every `git push` | Checks the cumulative branch diff. Push **fails** if `src/` was changed with no corresponding update to `plan/`, `docs/`, or `component.yml`. |
| **3: CI/CD pipeline** | Every pull request | Same check in GitHub Actions. Blocks the merge button if the rule is violated. Also fails a PR description that holds an AI attribution line. |
| **Release tag** | Every push to `main` or `master` | The `release-tag` job tags the merge commit with `v{version}`. |

One parity check applies to every diff. There is no relaxed rule for any commit prefix.

### commit-msg hook

A fourth git hook validates every commit message against `standards/commit-standards.md`. It blocks AI attribution lines, affirmatory language, and subjects over 72 characters. It exits 1 on violation. Use `git commit --no-verify` to bypass intentionally.

### Hook file locations

| File | Purpose |
|------|---------|
| `ravintio-zero/hooks/pre-commit` | Tier 1 advisory check |
| `ravintio-zero/hooks/pre-push` | Tier 2 blocking check |
| `ravintio-zero/hooks/commit-msg` | Commit message validation |
| `.github/workflows/ravintio.yml` | Tier 3 CI check (copied to the repo on first setup) |

Hooks are wired via `git config core.hooksPath ravintio-zero/hooks`, with no `.git/` directory modifications. Hooks travel with the repo and apply to every contributor who has run `setup.sh`.

### What happens on a Tier 2 violation

The push is rejected with a message naming the rule: `src/` was modified with no corresponding update under `plan/`, `docs/`, or any `component.yml`. To fix it, update `plan/` or `docs/` to reflect the `src/` change, then push again.

---

## Orchestrator Sentinel

### Lifecycle

When discovery starts, the orchestrator writes `plan/.orchestrator-active` containing the active feature-id (for example `0000002-doc-structure`). This file is the sentinel. Its presence signals that a pipeline run is in progress. It is deleted **last** during ship, after the archive is confirmed complete.

```
Discovery start     → plan/.orchestrator-active written ("pending" until feature-id confirmed)
Discovery complete  → plan/.orchestrator-active updated with confirmed feature-id
Plan to validate    → sentinel present, hooks enforce scope on every turn
Ship complete       → plan/.orchestrator-active deleted (final cleanup step)
```

### Sentinel enforcement hooks

| Hook | Trigger | What it does |
|------|---------|-------------|
| **gate-write** (PreToolUse: Write, Edit) | Every file write or edit | Gates every in-project path that is not always permitted (`plan/`, `docs/`, and listed basenames such as `CLAUDE.md`). Blocks the write unless `plan/current/design.md` exists AND the target path matches a declared component. Writes to `plan/current/` also need the `plan/.orchestrator-active` sentinel. Targets outside the project pass |
| **check-orchestrator-presence** (UserPromptSubmit) | Every user prompt while the sentinel is present | Injects a reminder banner so the orchestrator skill reloads after context compaction or session resume. Advisory by default, see Strict Mode below |
| **check-design** (UserPromptSubmit) | Every user prompt | If neither the sentinel nor a `feature-brief.md` is present, injects a hard STOP message before the agent can act. Prevents free-form changes outside the pipeline |

### How gate-write interacts with design.md

`gate-write` gates this project only. It resolves the project root and the target to real paths. A target whose real path lies outside the project passes, even through a symlink.

For an in-project target, `gate-write` runs these checks:

1. A write to `plan/current/` needs the `plan/.orchestrator-active` sentinel. The feature brief and the always-permitted basenames skip this check.
2. A path under `plan/` (including `plan/backlog/` and `plan/roadmap/`) or `docs/`, or an always-permitted basename, passes.
3. For every other path, `plan/current/design.md` must exist.
4. The target path must sit under a component path declared in the design's `## Component Paths` section.

The always-permitted basenames are `CLAUDE.md`, `AGENTS.md`, `.ravintio-session`, `.skips`, `.feature-id`, `.gitignore`, `.gitattributes`, `.claudeignore`, and `pause.md`. The `ravintio-zero/` and `ravintio-overrides/` folders get no exemption.

### Manual recovery

If a pipeline run is interrupted and you want to start fresh:

```bash
# 1. Delete the sentinel
rm plan/.orchestrator-active

# 2. Delete the active feature brief
rm plan/current/feature-brief.md

# 3. Optionally clear the current plan artifacts
rm -rf plan/current/

# 4. Reload the orchestrator. It begins a fresh discovery.
```

Do not delete `plan/_archive/` or `plan/changelog/`. These are historical records.

---

## Strict Orchestrator Mode

By default, `check-orchestrator-presence` is advisory. It injects a reminder banner but never blocks the session. Strict mode turns this into a hard gate.

### How it works

Enable strict mode at setup time:

```bash
# macOS / Linux
./ravintio-zero/setup.sh claude-code --strict-orchestrator
```

```powershell
# Windows (PowerShell)
.\ravintio-zero\setup.ps1 claude-code --strict-orchestrator
```

This writes `plan/.orchestrator-strict`. When that file is present, `check-orchestrator-presence` changes behaviour:

1. **On every new session**, it injects a hard-block banner that prevents the agent from acting until the orchestrator skill loads
2. **When the orchestrator loads**, it reads the `session_id` from the banner (injected by the hook) and writes it to `plan/.orchestrator-ack`
3. **On subsequent prompts in the same session**, the hook reads `plan/.orchestrator-ack`, sees the current session_id matches, and passes silently
4. **During ship**, the agent deletes `plan/.orchestrator-ack` so the next session starts clean

### The ack file

`plan/.orchestrator-ack` contains either:

- The `session_id` value injected by the hook banner (if available in the prompt context), or
- The current UTC timestamp in ISO 8601 format (fallback when no session_id is present)

The hook compares the stored value against the current session to determine whether the orchestrator has loaded in this session. The ack file is session-scoped, one value per pipeline session.

---

## Retrofit an Existing Project

Adoption modes let the pipeline start from a codebase that already has source code.

1. Copy `ravintio-zero/` into your repo root
2. Run the setup script (see [getting-started.md](getting-started.md#3-run-the-setup-script))
3. Add a `component.yml` manifest to each existing component in `src/`, using the [component manifest template](templates/component.template.yml) and [guide](templates/component-guide.md)
4. Tell the orchestrator to use **retrofit** adoption mode:

```
Run the RAVINTIO pipeline in retrofit mode.
Feature brief: plan/current/feature-brief.md
```

In retrofit mode, discovery includes a codebase scan before coaching. The orchestrator scans entry points and build files, identifies candidate components, maps data ownership, discovers API contracts, notes conventions the pipeline must preserve, and flags tech debt into the risk register. It then presents a discovery summary. Many coaching questions are pre-answered by the scan.

---

## Updating the pack

"Updating the pack" means pulling new files into `ravintio-zero/` (via git pull, a submodule update, or copying from the source repo) and then re-running the setup script to propagate the changes.

### Re-run setup after update

Pass the same flags you used during initial setup. Re-running is idempotent. It overwrites generated copies, prunes retired skills, and writes the setup-flags record to `plan/state/{tool}.md`. If a pre-relocation record for the tool still exists under `ravintio-overrides/`, setup removes it inline and otherwise leaves `ravintio-overrides/` alone. The `ravintio-refresh-setup` skill can reconstruct the flags in effect from `plan/state/{tool}.md` and re-run setup for you.

```bash
# macOS / Linux
./ravintio-zero/setup.sh claude-code
```

```powershell
# Windows (PowerShell)
.\ravintio-zero\setup.ps1 claude-code
```

### Check for pending migrations

After pulling a new version of `ravintio-zero/`, check for pending migrations before starting a new pipeline run:

```bash
ls ravintio-zero/migrations/*.md 2>/dev/null | grep -v _done
```

```powershell
Get-ChildItem ravintio-zero/migrations/*.md | Where-Object { $_.FullName -notmatch '_done' }
```

If any `.md` files appear outside `_done/`, the orchestrator detects them at session start and invokes `ravintio-migrator` before any pipeline work. You do not need to run migrations manually.

---

## What to Commit

| Path | Commit? | Why |
|------|:-------:|-----|
| `ravintio-zero/` | Yes | Source of truth, shared with the whole team |
| `ravintio-zero/hooks/` | Yes | Git hooks and CI workflow, applied by setup scripts |
| `.github/workflows/ravintio.yml` | Yes | CI/CD gate, must be committed to take effect in GitHub Actions |
| `plan/` | Yes | Feature briefs, execution plans, ADRs, scope docs. Design history |
| `plan/state/` | Yes | Machine-written setup-flags record per tool, for example `plan/state/claude-code.md`. Rewritten by every setup run, but stays git-tracked |
| `src/` | Yes | Component code and manifests |
| `docs/` | Yes | Repo-wide registry and dependency graph |
| `ravintio-overrides/` | Yes | Customisations, must be committed to be shared |
| `.claude/` | Optional | Generated copies, can be `.gitignore`d and regenerated by `setup.sh` |
| `CLAUDE.md` | Optional | Boot file, regenerated by setup. Commit it if you want it in the repo for contributors |

### When to commit plan/

Commit `plan/current/` artifacts throughout the pipeline run, not only at ship. Each phase produces artifacts (design, requirements, ADRs, execution plan) that are worth preserving in git history as they are written. On a feature branch this is low risk and provides a clear record of how the design evolved. Ship archives the completed plan to `plan/_archive/` and clears `plan/current/`, and that is a separate commit, not the first one.

### What "Optional" means

Optional paths are generated by the setup script from sources in `ravintio-zero/`. You can safely `.gitignore` them and instruct contributors to run `setup.sh` after cloning. This keeps the repo lean. Alternatively, commit them so contributors get the files without running setup. Both approaches work.

`ravintio-overrides/` is never optional. It contains your customisations and must be committed to be shared.

---

## Customising with ravintio-overrides

`ravintio-overrides/` is your customisation layer, committed to the repo and never overwritten by setup scripts.

### instructions/

Project-specific instructions appended to the `CLAUDE.md` boot file on every setup run. Idempotent: re-running setup replaces the previous block.

```
ravintio-overrides/
└── instructions/
    └── 01-project-context.md
    └── 02-naming-conventions.md
```

Files are sorted alphabetically and appended between HTML comment markers.

Keep in `instructions/` only the rules that every session needs. The boot file loads whole in each session. A rule that serves one task belongs in a skill.

To send an override to one pack skill, add a `target:` field to its frontmatter:

```
---
target: ravintio-ship
---
### Ship: push and raise the PR, never merge
```

Setup removes the frontmatter and appends the text to the installed `ravintio-ship` skill between the same markers. The boot file does not hold it. The value must be lowercase letters, digits, and hyphens, and must name an installed skill. If it does not, setup warns and appends the override to the boot file, so no rule is lost. An override with no `target:` goes to the boot file as before.

The hook rules live in `ravintio-zero/standards/hook-enforcement.md`. The boot files point to it, and each blocking hook names it in its message.

### capability-skills/

Permanent agent skills for this project. Each skill is a directory containing a `SKILL.md` with standard frontmatter. A task rule that runs on demand fits here, such as a `gutd` skill that syncs `main`. Setup copies them into `.claude/skills/` alongside the built-in RAVINTIO skills:

```
ravintio-overrides/
└── capability-skills/
    └── my-project-skill/
        └── SKILL.md
```

### library-standards/

Override the pack's library preferences per language. Files here take precedence over `ravintio-zero/standards/library-standards/`:

```
ravintio-overrides/
└── library-standards/
    └── typescript/
        └── prefer-avoid.md    ← replaces the pack default for TypeScript
```

Agents check `ravintio-overrides/library-standards/` first. Structure matches the pack default.

---

*Source of truth: `ravintio-zero/`. See [getting-started.md](getting-started.md) for setup steps.*
