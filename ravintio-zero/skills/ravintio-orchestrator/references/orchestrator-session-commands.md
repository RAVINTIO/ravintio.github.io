---
title: "Orchestrator reference: Session commands"
summary: "Phase Skip Protocol, Pause Command, and Park Command."
status: "active"
version: "1.0.0"
---
# Orchestrator reference: Session commands

> Moved verbatim from `SKILL.md`. Read this file before you act on the topic. The Pack Index in `SKILL.md` lists the trigger.

## Phase Skip Protocol

When the human explicitly asks to skip a phase:

1. Acknowledge immediately. Do not argue or ask for justification.
2. Append to `plan/current/.skips` in the same turn: `{phase}: skipped by human on {ISO-8601 date} ({reason, or "no reason given"})`
3. Continue to the next phase. The ship phase reads `.skips` into the changelog.

## Pause Command

When the human says "pause" or similar:

1. Note the active phase, the task in progress, and the last artifact written.
2. Read `ravintio-zero/templates/pause.template.md` and write `plan/current/pause.md` with state sufficient for exact-point resume.
3. Confirm: `{prefix}: Paused: {active_task}. Pause record written. Resume by loading ravintio-orchestrator in a new session.`
4. Stop all pipeline work.

## Park Command

When the human says "park" or similar, shelve the feature on its branch and return the working tree to `main`. The git and `gh` steps live in `scripts/park.mjs` beside this skill. Its header documents the arguments.

1. Read `ravintio-zero/templates/park.template.md` and write `plan/current/park.md` on the feature branch. Fill all four fields: phase reached, last artifact, head commit, and reason.
2. Commit `park.md`, then push the feature branch. Run `node scripts/park.mjs park --entry {entry file} --backlog-id {next backlog id}` to do steps 2 to 5.
3. Cut `chore/park-{feature-id}` from `main`. Add a backlog entry from `ravintio-zero/templates/backlog-entry.template.md` with status `parked` and a `**Parked branch:**` field that names the feature branch. Write the entry outside the working tree and pass its path as `--entry`.
4. Push the chore branch and run `gh pr create`.
5. Check out `main`. Confirm: `{prefix}: Parked: {feature-id} on {branch}. Chore PR raised. Merge it to file the parked entry.`

Rules:

- If `plan/current/design.md` does not exist, the phase reached is P0.
- The sentinels in `plan/` live on the feature branch only. Park removes nothing from `main`.
- The parked entry reaches `main` only when the human merges the chore PR. Until then, a session on `main` does not see it.
- If any push or `gh` call fails, report the exact error and stop. The working tree stays on the feature branch, and `park.md` stays committed locally.
- Park never merges a pull request, never commits to `main`, and never force-pushes.
- `park.mjs` refuses `main`, an option or full ref name as a branch, a backlog id that is not seven digits, and a slug that is not kebab-case. If it refuses, report the error and stop.
- Allow one park per working tree. If another feature's `chore/park-*` branch exists, do not open a second park. Ask the human to finish that one first.
