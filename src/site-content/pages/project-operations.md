# Project operations

This page covers the day-to-day running of a Zero project. It explains what the hooks enforce, how commit messages are checked, how to customise Zero, and what to commit. To install Zero first, see [Install Zero](install-zero.md).

## Git guardrails

Setup activates git hooks and a CI workflow. They protect `main` without blocking small commits.

| Tier | When | Effect |
|------|------|--------|
| Pre-commit | Every local commit | Warns if code is staged without documentation. The commit succeeds. |
| Pre-push | Every push | Fails if `src/` changed with no update to `plan/`, `docs/`, or a `component.yml`. |
| CI | Every pull request | Runs the same check in GitHub Actions. It also fails a description that holds an AI attribution line. |
| Release tag | Every push to `main` | The `release-tag` job tags the merge commit with `v{version}`. |

The parity check tests presence only. It does not verify that the documentation matches the code. Reviewers check that.

If a push fails the parity check, update `plan/` or `docs/` to reflect the `src/` change, then push again.

## Enforcement hooks

On Claude Code, setup wires these hooks into `.claude/settings.json`. On Codex, only `merge-guard` runs.

| Hook | Trigger | What it does |
|------|---------|--------------|
| `gate-write` | Before a write or edit | Blocks writes unless `plan/current/design.md` exists and the path belongs to a declared component. It can't see whether you confirmed the design. |
| `ratchet-check` | Before a write or edit | During a loop, blocks edits that weaken acceptance criteria or scope. |
| `em-dash-guard` | Before a write or edit | Rejects em dashes in `plan/current/`, `docs/`, and the pack's `skills/`, `templates/`, and `standards/` folders. Add `<!-- ravintio-em-dash-allow -->` to a write to allow it. |
| `check-design` | On each prompt | Injects the active component scope, or a stop message if there is no brief and no sentinel. |
| `check-orchestrator-presence` | On each prompt | Reminds the agent to load the orchestrator while a run is active. |
| `auto-trigger-orchestrator` | On each prompt | Loads the orchestrator at session start when no run is active. |
| `check-reply-prefix` | When a reply ends | Warns about a missing phase prefix and logs it. It never blocks. |
| `merge-guard` | Before a shell command | Blocks `gh pr merge` unless it squashes into an `initiative/*` branch. |

A blocking hook exits with a message. If a hook blocks you, read `ravintio-zero/standards/hook-enforcement.md`. The [standards](standards.md) page describes it. Every hook fails open on an unexpected error, so a broken hook never stops a session.

## Commit standards

Follow this form for every commit message.

```text
type(scope): short description
```

- The type is one of `feat`, `fix`, `docs`, `chore`, `refactor`, `test`, or `perf`.
- The scope is a feature id such as `0000003`, or a component id.
- The subject uses the imperative mood and stays within 72 characters.

The `commit-msg` hook enforces only part of this. It rejects:

- AI attribution, including `Co-Authored-By` lines that name an AI tool and `Claude-Session:` lines
- Affirmatory phrases, such as "Done" or "Working now"
- Subjects over 72 characters

The hook does not check the type or the scope. To bypass it on purpose, run `git commit --no-verify`.

The person who commits owns the commit. The AI tool is not a contributor of record. See [standards](standards.md) for the full commit standard.

## The orchestrator sentinel

When discovery starts, the orchestrator writes `plan/.orchestrator-active`. It holds the active feature id. The hooks read it to know a run is in progress. Ship deletes it after it confirms the archive and before it pushes, so no pull request carries it. You never create or delete it by hand during a run.

If a run stops and you want a fresh start, take these steps.

1. Delete `plan/.orchestrator-active`.
2. Delete `plan/current/feature-brief.md`.
3. Optionally clear the rest of `plan/current/`.
4. Reload the orchestrator. It begins a new discovery.

Do not delete `plan/_archive/` or `plan/changelog/`. They are your history.

## Strict orchestrator mode

By default, `check-orchestrator-presence` only reminds the agent. Strict mode makes each session prove that it loaded the orchestrator. Turn it on at setup.

```bash
./ravintio-zero/setup.sh claude-code --strict-orchestrator
```

```powershell
.\ravintio-zero\setup.ps1 claude-code --strict-orchestrator
```

Setup then writes `plan/.orchestrator-strict`. The handshake works like this.

1. On each prompt during an active run, the hook reads the session id.
2. If `plan/.orchestrator-ack` is missing or holds another id, the hook prints a `RAVINTIO STRICT MODE` banner.
3. When the orchestrator loads, it writes the session id to `plan/.orchestrator-ack`.
4. While the file holds the current id, the hook stays quiet.

A new session sees the banner again until its orchestrator loads. Ship deletes the file with the other sentinels.

## Customise with `ravintio-overrides/`

The `ravintio-overrides/` folder holds your customisations. Commit it. Setup never overwrites it.

| Folder | Purpose |
|--------|---------|
| `instructions/` | Project instructions. Setup adds them to the boot file on every run, sorted by name. |
| `capability-skills/` | Permanent skills that install beside the built-in ones. Each skill is a folder with a `SKILL.md`. |
| `library-standards/` | Your library preferences per language. Agents check here before the pack defaults. |

Do not edit files inside `ravintio-zero/` for a single project. Put project changes in `ravintio-overrides/` so a pack update does not erase them.

## Backlog and ids

The backlog holds deferred items. Each entry is a folder, `plan/backlog/{id}-{slug}/`, with an `entry.md` file.

- Ids come from the counter in `plan/backlog/.next-id`. A spent id never returns.
- Backlog, feature, and initiative ids share one counter.
- The agent reserves ids with `node ravintio-zero/scripts/reserve-id.mjs`.
- At the start of discovery, the agent offers each entry to you. You pull it in, leave it, or discard it.
- A `parked` entry offers resume or discard instead.

To file an entry in another repository, ask the agent to file a backlog entry there. The `ravintio-file-backlog` skill writes it and leaves that repository's git state alone.

## Update the pack

After you pull new files into `ravintio-zero/`, re-run setup with your original flags.

```bash
./ravintio-zero/setup.sh claude-code
```

Re-running overwrites the generated copies, prunes retired skills, and rewrites the setup record in `plan/state/`. Then check `ravintio-zero/migrations/` for pending files. The orchestrator applies them at the next session start.

The orchestrator also detects a pack update on its own. It asks you to confirm two facts, that this is a pack update and where it came from. It records the answer in the build log. If you reject it, the agent treats the new files as untrusted.

## What to commit

| Path | Commit | Why |
|------|--------|-----|
| `ravintio-zero/` | Yes | The pack is shared with the team. |
| `.github/workflows/ravintio.yml` | Yes | The CI gate only works once committed. |
| `plan/` | Yes | It holds briefs, plans, and decision records. Commit throughout the run. |
| `plan/state/` | Yes | It records the setup flags per tool. |
| `src/` | Yes | Component code and manifests. |
| `docs/` | Yes | The repository registry and dependency graph. |
| `ravintio-overrides/` | Yes | Your customisations. |
| `.claude/` | Optional | Setup generates it, so you can ignore it and regenerate. |
| `CLAUDE.md` | Optional | Setup regenerates it. |

Commit the contents of `plan/current/` as the phases write them. Ship archives the plan in a separate commit.
