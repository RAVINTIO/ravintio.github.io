# Install Zero

You install Zero by copying one folder, `ravintio-zero/`, into your repository and running a setup script. The script wires the skills and hooks for your agent tool. This page covers a new repository and an existing one.

## Prerequisites

- Claude Code or Codex
- Node, because the hooks and scripts run as `node` scripts. The pack states no minimum version.
- Git
- A GitHub remote named `origin`. The pre-push hook fetches `origin/main`, and ship pushes to it.
- The `gh` command line tool, installed and signed in. The agent uses it to raise pull requests.
- A terminal with Bash on macOS or Linux, or PowerShell on Windows

Run setup from the repository root.

If `gh` is missing in an autonomous run, ship stops with `Blocked`. A gated run offers a printed PR description instead.

## Get the pack

1. Clone the pack repository to a location outside your project.

   ```bash
   git clone https://github.com/RAVINTIO/ravintio-zero
   ```

2. Find the `ravintio-zero/` folder in the clone. This folder holds the skills, templates, standards, hooks, and setup scripts.

## Install into a new repository

1. Create the repository and enter it.
2. Copy the `ravintio-zero/` folder into the repository root.
3. Run setup for your tool.

   ```bash
   # macOS or Linux, Claude Code
   chmod +x ravintio-zero/setup.sh
   ./ravintio-zero/setup.sh claude-code
   ```

   ```powershell
   # Windows, Claude Code
   .\ravintio-zero\setup.ps1 claude-code
   ```

4. If you use Codex, pass `codex` instead of `claude-code`.

   ```bash
   ./ravintio-zero/setup.sh codex
   ```

5. Commit the setup to `main`, or merge a setup pull request, before you start the first feature. The agent cuts the feature branch from `main`.

Setup creates `src/` and `plan/`. The agent creates the other working folders when a run needs them.

## Install into an existing repository

> **Warning:** Setup regenerates `CLAUDE.md` or `AGENTS.md` from a template. Before you run it, move your own instructions into `ravintio-overrides/instructions/`. Setup appends those files to the boot file on every run. Setup also changes `.claude/settings.json`. See [what setup changes](#what-setup-changes).

1. Copy the `ravintio-zero/` folder into the repository root.
2. Run the setup script for your tool, as in the previous section.
3. Make sure each existing component lives under `src/`. Add a `component.yml` manifest to each one. Use the component manifest template and guide. See [templates](templates.md).
4. Start the agent. It detects the adoption mode and recommends one for you to confirm, as the next section describes.

### Adoption modes

The orchestrator picks an adoption mode from signals in your repository. It applies the first signal that matches, then asks you to confirm.

| Mode | Signal | What changes |
|------|--------|--------------|
| External anchor | `ravintio-overrides/instructions/external-versioning.md` exists | The agent asks you about the external version constraint and adds it to the rules. |
| Standard iterative | `plan/_archive/` holds a feature folder, or `docs/about.md` exists | Earlier decisions count as constraints. The default version bump is minor. |
| Retrofit | `src/` holds source code and there is no archive or overrides | Discovery scans the codebase before it asks questions. |
| Greenfield | None of the above | The version starts at `0.1.0` and coaching starts from your brief. |

The retrofit scan records version markers, entry points, components, data ownership, API contracts, conventions, and visible tech debt. The scan answers many questions for you.

If it detects the wrong mode, tell it. For example, ask for retrofit mode with this prompt.

```text
Run the RAVINTIO pipeline in retrofit mode.
Feature brief: plan/current/feature-brief.md
```

If you name a mode that conflicts with the detected signal, the agent warns you once. It proceeds if you confirm.

## What setup changes

Setup writes into your repository. It reads `ravintio-overrides/` and does not edit your files there.

| Change | Claude Code | Codex |
|--------|-------------|-------|
| Skills | Copied into `.claude/skills/` | Copied into `.agents/skills/` |
| Boot file | `CLAUDE.md`, regenerated from a template on every run | `AGENTS.md`, regenerated the same way |
| Enforcement hooks | Wired into `.claude/settings.json` | `merge-guard` only, in `.codex/hooks.json` |
| Settings | Adds `Agent` to the allowed tools. Sets empty commit and PR attribution if you have none. | None |
| Command | Copies `feature-pipeline.md` into `.claude/commands/` | None |
| Git hooks | `core.hooksPath` points at `ravintio-zero/hooks` | Same |
| CI workflow | Copied to `.github/workflows/ravintio.yml` on first setup | Same |
| Repository files | Writes `.gitignore`, `.gitattributes`, and `.claudeignore` if missing. Writes `src/README.md`, `plan/README.md`, and `plan/feature-structure.md` if missing. | Same |
| Setup record | `plan/state/claude-code.md` | `plan/state/codex.md` |

Setup also prunes skills that the pack has retired. It does not copy templates, standards, or schemas. Skills read those from `ravintio-zero/`.

## Optional strict mode

Add `--strict-orchestrator` to make every session prove that it loaded the orchestrator.

```bash
./ravintio-zero/setup.sh claude-code --strict-orchestrator
```

```powershell
.\ravintio-zero\setup.ps1 claude-code --strict-orchestrator
```

See [project operations](project-operations.md#strict-orchestrator-mode) for how the handshake works.

## Check that the hooks registered

1. Check the git hooks path.

   ```bash
   git config core.hooksPath
   ```

   The command prints `ravintio-zero/hooks`.

2. For Claude Code, open `.claude/settings.json`. Confirm that a `hooks` section lists the enforcement hooks, such as `gate-write` and `check-design`.
3. For Codex, read the setup output. It lists the active hook and the fallback rules. Then run `/hooks` in Codex and trust the project hook. Until you trust it, Codex skips `merge-guard`.
4. Confirm that `.github/workflows/ravintio.yml` exists. Commit it, because it only takes effect once committed.

## Update or refresh later

1. Pull the new pack files into `ravintio-zero/`. Use `git pull`, a submodule update, or a copy from the source repository.
2. Re-run the setup script with the same flags you used the first time. Re-running is safe to repeat.
3. Check `ravintio-zero/migrations/` for pending `.md` files outside `_done/`. The orchestrator applies them at the next session start with the `ravintio-migrator` skill.
4. If you do not remember your flags, ask the agent to refresh the RAVINTIO setup. The `ravintio-refresh-setup` skill reads `plan/state/{tool}.md` and re-runs setup for you.

Next, follow [your first run](first-run.md).
