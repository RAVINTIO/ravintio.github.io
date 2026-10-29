---
title: "Hook enforcement"
summary: "What each RAVINTIO enforcement hook does, and which hooks Codex runs."
status: "active"
version: "0.1.0"
---
# Hook enforcement

Read this file when a hook blocks an action. Each block message names it.

## Claude Code

RAVINTIO installs these deterministic enforcement hooks via `setup.sh`:

- **gate-write** (PreToolUse: Write, Edit): Gates every in-project path that is not always permitted. The write needs `plan/current/design.md` AND a declared component match. `plan/current/` also needs `plan/.orchestrator-active`. `plan/` (with `plan/backlog/` and `plan/roadmap/`), `docs/`, and permitted basenames pass. Targets outside the project pass.
- **auto-trigger-orchestrator** (UserPromptSubmit): At the start of every session in a RAVINTIO project (`ravintio-zero/` present and `plan/.orchestrator-active` absent), automatically loads the `ravintio-orchestrator` skill before the first prompt is processed. This is the primary trigger mechanism for Claude Code.
- **check-design** (UserPromptSubmit): Injects active component scope from `design.md` as additional context.
- **check-reply-prefix** (Stop): While a run is active, warns when a reply lacks a valid phase or stage prefix and logs the miss to `plan/.prefix-misses.log`. It never blocks.
- **commit-msg** (git hook): Blocks commits that break `commit-standards.md`. Exit 1 on violation; use `git commit --no-verify` to bypass intentionally.
- **ratchet-check** (PreToolUse: Write, Edit): While a loop is active (a `plan/current/loop-state-*.md` with `status: active`), blocks writes that remove acceptance-criteria or in-scope lines from `plan/current/` artifacts. Strengthening passes; intentional weakening needs a human-written `plan/current/.ratchet-approve` line (single-use). Agents must never write that marker.

Enforcement failures exit 2 and surface a human-readable message. All unexpected errors exit 0; hooks never block your session unexpectedly.

## Codex

Codex runs fewer RAVINTIO hooks than Claude Code. Setup wires the hook below. You enforce every other rule yourself.

Active hooks, wired in `.codex/hooks.json`:

- **merge-guard** (PreToolUse: Bash): Blocks any pull request merge command unless it squash-merges your own feature PR into an `initiative/*` base. Merging into `main` is human-only.

Fallback hooks, which Codex does not run for RAVINTIO. Follow each rule as an instruction:

- **gate-write**: Before you write any file, confirm that `plan/current/design.md` exists and that the path belongs to a declared component. `plan/current/` also needs `plan/.orchestrator-active`. `plan/`, `docs/`, and always-permitted basenames pass. Never write application code without a confirmed design.
- **ratchet-check**: While a loop is active (a `plan/current/loop-state-*.md` with `status: active`), never remove acceptance-criteria or in-scope lines from `plan/current/` artifacts. Never write `plan/current/.ratchet-approve`.
- **em-dash-guard**: Write no em dash (U+2014) in RAVINTIO prose paths.
- **auto-trigger-orchestrator**: At the start of every session in a RAVINTIO project (`ravintio-zero/` present and `plan/.orchestrator-active` absent), load the `ravintio-orchestrator` skill before you process the first prompt.
- **check-orchestrator-presence**: In strict mode (`plan/.orchestrator-strict` present), load the orchestrator and write your session ID to `plan/.orchestrator-ack` before you act.
- **check-design**: At the start of each prompt, read the active component scope in `plan/current/design.md`.
- **check-reply-prefix**: Begin every reply in an active run with a valid prefix, as the reply conventions in the boot file describe.
- **commit-msg** (git hook): Blocks commits that break `commit-standards.md`. Exit 1 on violation. Use `git commit --no-verify` to bypass intentionally.

Project hooks run only after a person trusts them. Run `/hooks` in Codex to review and trust the RAVINTIO hook. Until a person trusts the hook, nothing blocks a merge, including in `codex exec`. Never run a pull request merge command against `main` yourself.
