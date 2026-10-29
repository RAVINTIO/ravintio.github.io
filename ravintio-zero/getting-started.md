# Getting Started with RAVINTIO

> Step-by-step instructions for humans setting up a RAVINTIO project.
> For day-to-day operations reference, see [project-operations.md](project-operations.md). For deep pipeline mechanics, see [pipeline-reference.md](pipeline-reference.md).

---

## Prerequisites

- Claude Code
- Node (the hooks and scripts run as `node` scripts)
- A terminal with Bash (macOS/Linux) or PowerShell (Windows)

---

## New Project

### 1. Add the pack

Copy the `ravintio-zero/` folder into your repository root. This folder is all you need. It contains the skills, templates, standards, hooks, and setup scripts.

### 2. Create the project structure

```
mkdir -p plan/current plan/changelog plan/backlog src docs
```

These are the core working directories:

- `plan/` holds the change in progress and its records.
  - `plan/current/` is the change in progress: `feature-brief.md`, `design.md`, `build-log.md`, and the plan artifacts.
  - `plan/_archive/` holds completed runs, filed at ship.
  - `plan/changelog/` holds one change record per feature (`{feature-id}-{YYYY-MM-DD}.md`).
  - `plan/backlog/` holds deferred items.
  - `plan/roadmap/` holds draft initiatives, and `plan/current-initiative/` holds the one active initiative. See [roadmap-standards.md](standards/roadmap-standards.md).
- `src/` holds component source code, tests, and component manifests (`component.yml`).
- `docs/` holds the living repository documentation, always current. It includes the component registry and dependency graph.
- `ravintio-overrides/` holds your customisations: project instructions, capability skills, setup config, and library standards. Setup never overwrites it. See [project-operations.md, Customising](project-operations.md#customising-with-ravintio-overrides).

See [feature-structure.md](../plan/feature-structure.md) for the full layout.

### 3. Run the setup script

Setup supports two tool targets, `claude-code` and `codex`.

#### Basic setup

```bash
# macOS / Linux
chmod +x ravintio-zero/setup.sh
./ravintio-zero/setup.sh claude-code
```

```powershell
# Windows (PowerShell)
.\ravintio-zero\setup.ps1 claude-code
```

Setup installs:

- Skill folders with YAML frontmatter into `.claude/skills/`, auto-discovered by Claude Code. Retired skills are pruned.
- No copies of templates, standards, or schemas. Skills read them from `ravintio-zero/` by full path.
- Enforcement hooks wired into `.claude/settings.json`.
- The `CLAUDE.md` boot file.
- Git hooks and the orchestrator sentinel machinery, activated automatically.

#### Codex setup

To install for Codex, run `./ravintio-zero/setup.sh codex` or `.\ravintio-zero\setup.ps1 codex`. Setup installs:

- Skill folders into `.agents/skills/`, which Codex scans from the working directory up to the repo root.
- The `AGENTS.md` boot file.
- The `merge-guard` hook in `.codex/hooks.json`, with its scripts in `.codex/hooks/enforcement/`.
- The git hooks and the orchestrator sentinel machinery, as for Claude Code.

Codex runs only the `merge-guard` hook. Setup prints the active and fallback hooks. `AGENTS.md` states each fallback rule as an instruction. Run `/hooks` in Codex to review and trust the project hook. Until you trust it, Codex skips `merge-guard`, including in `codex exec`.

→ **Git guardrails and the orchestrator sentinel** are activated automatically by setup. See [project-operations.md](project-operations.md) for how they work and how to enable strict mode.

### 4. Write your first feature brief

Use the template:

```
cp ravintio-zero/templates/feature-brief.template.md plan/current/feature-brief.md
```

Fill it in. The [feature brief guide](templates/feature-brief-guide.md) walks you through each section.

Every agent response begins with a phase prefix, from `P0 Discovery:` to `P4 Ship:`, so you always know where you are in the pipeline. See [pipeline-reference.md, Phase indicators](pipeline-reference.md#phase-indicators) for the full table.

### 5. Start the orchestrator

Open Claude Code in the project. The auto-trigger hook loads the orchestrator skill at the start of the session. Tell it:

```
Run the RAVINTIO pipeline.
Feature brief: plan/current/feature-brief.md
```

The orchestrator runs discovery: it assesses your brief, coaches you through any gaps, and produces a confirmed design. It then asks how the agent should run P1 to P4. Gated stops for you at the end of each phase. Autonomous runs to a raised PR and stops only for escalations.

To chain several features, ask the orchestrator to chart an initiative. You approve it once, and a driver script runs each step. See [roadmap-standards.md](standards/roadmap-standards.md).

Every change takes this route. A small change is a small run, not a different pipeline.

---

## Next Steps

| Topic | Where to look |
|-------|---------------|
| Git guardrails and how enforcement works | [project-operations.md](project-operations.md#git-guardrails) |
| Orchestrator sentinel and strict mode | [project-operations.md](project-operations.md#strict-orchestrator-mode) |
| Customising with ravintio-overrides | [project-operations.md](project-operations.md#customising-with-ravintio-overrides) |
| Updating the pack | [project-operations.md](project-operations.md#updating-the-pack) |
| What to commit | [project-operations.md](project-operations.md#what-to-commit) |
| Retrofit an existing project | [project-operations.md](project-operations.md#retrofit-an-existing-project) |
| Phase mechanics and confirmation gates | [pipeline-reference.md](pipeline-reference.md) |
| The 12 skills and who dispatches whom | [pipeline-reference.md, Skills](pipeline-reference.md#skills) |
