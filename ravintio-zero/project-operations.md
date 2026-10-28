# Project Operations

> Day-to-day operations reference for RAVINTIO projects. For first-time setup, start with [getting-started.md](getting-started.md). For detailed step-by-step coverage of every topic on this page, see [pipeline-reference.md](pipeline-reference.md).

---

## Git Guardrails

The setup script activates a **three-tier Progressive Guardrail System** that protects `main` without blocking atomic commits.

| Tier | When | Effect |
|------|------|--------|
| **1: Advisory pre-commit** | Every local commit | Warns if code was staged without docs. Commit **succeeds**. |
| **2: Branch pre-push** | Every `git push` | Fails if `src/` changed with no update to `plan/`, `docs/`, or `component.yml`. |
| **3: CI/CD pipeline** | Every pull request | Same check in GitHub Actions. Blocks the merge button on violation. Also fails a PR description that holds an AI attribution line. |
| **Release tag** | Every push to `main` or `master` | The `release-tag` job tags the merge commit with `v{version}`. |

A `commit-msg` hook also validates every commit message. It blocks AI attribution, affirmatory language, and subjects over 72 characters.

Hooks live in `ravintio-zero/hooks/` and are wired via `git config core.hooksPath`. No `.git/` modifications required. The CI workflow is copied to `.github/workflows/ravintio.yml` on first setup.

→ [Detailed guardrail mechanics and hook file locations](pipeline-reference.md#git-guardrails)

---

## Orchestrator Sentinel

When discovery starts, the orchestrator writes `plan/.orchestrator-active` containing the active feature-id. Hooks check for it on every turn:

| Hook | What it does |
|------|-------------|
| **gate-write** (PreToolUse) | Gates every in-project path that is not always permitted. Blocks the write unless `plan/current/design.md` exists and the target path is a declared component. Writes to `plan/current/` also need the `plan/.orchestrator-active` sentinel. Targets outside the project pass |
| **check-orchestrator-presence** (UserPromptSubmit) | Injects a reminder banner on every prompt while a pipeline is active, so the orchestrator skill reloads after context compaction or session resume |
| **check-design** (UserPromptSubmit) | Injects a hard STOP message if neither the sentinel nor a `feature-brief.md` is present |
| **auto-trigger-orchestrator** (UserPromptSubmit) | Loads the orchestrator skill at the start of a session when no pipeline is active yet |
| **check-reply-prefix** (Stop) | Warns when a reply in an active run lacks a valid phase prefix, and logs each miss to `plan/.prefix-misses.log`. It never blocks |
| **merge-guard** (PreToolUse, Bash) | Blocks `gh pr merge` unless it is a squash into an `initiative/*` branch. Merging into `main` stays human-only |

The sentinel is deleted last during ship, after the archive is confirmed complete. You never create or delete it manually.

**If a pipeline run is interrupted** and you want to start fresh: delete `plan/.orchestrator-active` and `plan/current/feature-brief.md`, then reload the orchestrator.

→ [Full sentinel lifecycle, hook internals, gate-write interaction with design.md, and manual recovery](pipeline-reference.md#orchestrator-sentinel)

---

## Strict Orchestrator Mode

Strict mode makes every session prove that it loaded the orchestrator. By default, `check-orchestrator-presence` is advisory: it prints a reminder banner and never blocks. Turn strict mode on with the `--strict-orchestrator` flag:

```bash
# macOS / Linux
./ravintio-zero/setup.sh claude-code --strict-orchestrator
```

```powershell
# Windows (PowerShell)
.\ravintio-zero\setup.ps1 claude-code --strict-orchestrator
```

Setup then writes `plan/.orchestrator-strict`.

### Strict mode and the session acknowledgement

The hook acts only while a pipeline is active, that is while `plan/.orchestrator-active` exists. Proof then works as a handshake:

1. On each prompt, the `check-orchestrator-presence` hook reads the session id that Claude Code passes to it.
2. If `plan/.orchestrator-ack` is missing or holds a different id, the hook prints a `RAVINTIO STRICT MODE` banner. The banner names the session id and asks the agent to load the orchestrator.
3. When the orchestrator loads, it writes that id to `plan/.orchestrator-ack`. The write acknowledges the banner, which is where the file gets its name.
4. While the file holds the current session's id, the hook stays quiet.

`plan/.orchestrator-ack` holds one line: the id of the session that last loaded the orchestrator. If the hook gets no session id, the banner asks for the current timestamp instead. The file is not a log or a lock. A new session finds an old id there and sees the banner again until its orchestrator loads.

Ship deletes the file with the other sentinels, before it raises the pull request. You never write it by hand.

While an initiative is active, the banner names the skill that owns the session. A step session gets the orchestrator and `plan/.orchestrator-ack`. Your own session gets the `ravintio-initiative` skill and `plan/.initiative-ack`, which git ignores.

In an initiative run, each step session writes its own id to `plan/.orchestrator-ack`. The `ravintio-initiative` session writes its own id to `plan/.initiative-ack`. The hook accepts either file, so strict mode stays quiet in every session.

→ [Strict mode internals and the session_id protocol](pipeline-reference.md#strict-orchestrator-mode)

---

## Roadmap and initiative glossary

This section defines the roadmap terms once. Other pack files link here.

- **Roadmap:** the long-term plan for the product. `plan/roadmap/` holds it, with one subfolder per roadmap initiative.
- **Roadmap initiative:** a goal that delivers a string of feature builds. Each build merges into the initiative's own branch, and that branch merges to `main` in one PR. After first mention, prose says "initiative".
- **Initiative states:** every initiative holds one of five states, and each stage of the lifecycle sets one:
  - `proposed`: Drafting sets it.
  - `charted`: I-A Chart sets it.
  - `active`: I-B Activate sets it.
  - `delivered`: I-E Delivery sets it.
  - `blocked`: any exception stop sets it.

### How an initiative runs

Three parts run an initiative. The human talks only to their own session. Step sessions run with no human present.

| Part | What it is | Runs where | Owns |
|------|-----------|------------|------|
| `ravintio-initiative` skill | The initiative coordinator | The human's session | Chart, activate, watching the steps, progress reports, and delivery |
| Driver, `initiative-run.mjs` | A script with no AI | A background task that the initiative skill starts | Starting each step session in turn, and stopping on a `Blocked:` line |
| `ravintio-orchestrator` skill | The feature coordinator | Each step session, a separate `claude -p` process | One feature from P0 to P4, then the merge into the initiative branch |

An initiative runs in this sequence:

1. **I-A Chart.** The initiative skill plans the steps with the human and takes their approval.
2. **I-B Activate.** The initiative skill cuts the initiative branch and starts the driver.
3. **I-C Run.** The driver starts a step session. It loads the orchestrator and builds one feature from P0 to P4.
4. **I-D Advance.** The step session merges its feature PR into the initiative branch, tags the merge commit, and exits.
5. The driver starts the next step session. Stages I-C and I-D repeat until no steps remain.
6. While steps run, the initiative skill watches the build log and git, and reports to the human. It never edits the working tree.
7. **I-E Delivery.** After the driver exits, the initiative skill archives the initiative and raises the initiative PR to `main`. It then gives the final report.

→ [Initiative stages and rules](standards/roadmap-standards.md)

---

## Customising with ravintio-overrides

`ravintio-overrides/` is your customisation layer. It is committed to the repo and never overwritten by setup scripts.

| Directory | Purpose |
|-----------|---------|
| `instructions/` | Project-specific instructions appended to the `CLAUDE.md` boot file on every setup run. Files sorted alphabetically and injected between HTML comment markers. |
| `capability-skills/` | Permanent agent skills installed alongside built-in RAVINTIO skills on every setup run. Each skill is a directory containing a `SKILL.md`. |
| `library-standards/` | Override the pack's library preferences per language. Agents check here before the pack defaults. Structure mirrors `ravintio-zero/standards/library-standards/`. |

The tracked record of setup flags per tool lives at `plan/state/{tool}.md`, not under `ravintio-overrides/`. The setup script writes it, and the `ravintio-refresh-setup` skill reads it.

→ [Full directory structure, file formats, and examples](pipeline-reference.md#customising-with-ravintio-overrides)

---

## Updating the pack

After pulling new files into `ravintio-zero/`, re-run the setup script to propagate changes. Pass the same flags used during initial setup. Re-running is idempotent, and it prunes skills the new version has retired.

```bash
# macOS / Linux
./ravintio-zero/setup.sh claude-code
```

```powershell
# Windows (PowerShell)
.\ravintio-zero\setup.ps1 claude-code
```

After updating, check `ravintio-zero/migrations/` for any pending `.md` files. The orchestrator handles them automatically at next session start via the `ravintio-migrator` skill.

→ [Full update protocol and migration handling](pipeline-reference.md#updating-the-pack)

---

## What to Commit

| Path | Commit? | Why |
|------|:-------:|-----|
| `ravintio-zero/` | Yes | Source of truth, shared with the team |
| `ravintio-zero/hooks/` | Yes | Git hooks and CI workflow, applied by setup scripts |
| `.github/workflows/ravintio.yml` | Yes | CI/CD gate, must be committed to take effect |
| `plan/` | Yes | Feature briefs, execution plans, ADRs, scope docs. Commit throughout the pipeline run, not only at ship |
| `plan/state/` | Yes | Machine-written setup-flags record per tool, rewritten by every setup run. Git-tracked state, not a `ravintio-overrides/` customisation |
| `src/` | Yes | Component code and manifests |
| `docs/` | Yes | Repo-wide registry and dependency graph |
| `ravintio-overrides/` | Yes | Customisations, committed to share with the team |
| `.claude/` | Optional | Generated copies, can be `.gitignore`d and regenerated by setup |
| `CLAUDE.md` | Optional | Boot file, regenerated by setup |

→ [What "Optional" means and commit message standards](pipeline-reference.md#what-to-commit)

---

## Retrofit an Existing Project

Add RAVINTIO to a codebase that already has source code.

1. Copy `ravintio-zero/` into your repo root
2. Run the setup script (see [getting-started.md, Run the setup script](getting-started.md#3-run-the-setup-script))
3. Add a `component.yml` manifest to each existing component in `src/`, using the [component manifest template](templates/component.template.yml) and [guide](templates/component-guide.md)
4. Tell the orchestrator to use **retrofit** adoption mode:

```
Run the RAVINTIO pipeline in retrofit mode.
Feature brief: plan/current/feature-brief.md
```

In retrofit mode, discovery includes a codebase scan before coaching. The orchestrator scans entry points, maps data ownership, discovers API contracts, and surfaces tech debt, then uses those findings to reduce the coaching questions you need to answer.

→ [Retrofit discovery scan details](pipeline-reference.md#retrofit-an-existing-project)
