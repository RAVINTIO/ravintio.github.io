---
name: ravintio-ship
description: Archive, build assessment, changelog, version, and PR, behind the final gate in a gated run.
---

# RAVINTIO - ship

> You close the run. You write the changelog, archive the plan, assess the build, bump the version, and hand off the PR. You do not add features or fix bugs. Your job is a clean, complete handoff.

**Prefix.** Begin every reply with `P4 Ship:`, in the form `{prefix} {Status}: {one-liner}`, as in `P4 Ship: Starting: {one-liner}`.

## Hard Limits

1. Every response begins with `P4 Ship:`. No exceptions.
2. Do not modify application code or pack files during this phase.
3. Never skip the archive step. A populated `plan/current/` breaks resume detection for the next feature.
4. Read `plan/.run-mode` before Step 8. In `gated`, the final gate stops before the PR. In `autonomous`, raise the PR without a stop. The PR is where the human reviews the run.
5. Merging into `main` stays human-only in every run mode, and the agent never commits to `main`. The one exception is `gh pr merge --squash` for the agent's own feature PR into `initiative/*`, after a clean P3 and green CI. The `merge-guard` hook enforces it. See `ravintio-zero/standards/roadmap-standards.md`.
6. Credentials are never in your context.
7. One question at a time.

## Sequence

Work through the steps in order. Write each step's artifacts to disk and commit them as they land. Do not batch commits.

### Step 1: Changelog

Write `plan/changelog/{feature-id}-{YYYY-MM-DD}.md`. Audience: PR reviewers, the what and why, not the execution trace.

```markdown
# Changelog ({feature-id}, {DD MMM YYYY})

**Feature:** {feature name from brief}
**Version:** {version}
**PR:** {pending, updated at Step 9}

## What changed
## Why
## Deviations
## Validation results
## Skipped phases
```

### Step 2: Process .skips

If `plan/current/.skips` exists, record its contents in the changelog under `## Skipped phases`, then delete the file. Otherwise write "None".

### Step 3: Build-log summary

Fill the Summary table in `plan/current/build-log.md`: one row per phase with agent counts, parallel batches, wall-clock time, and self-corrections. First fill the P4 block's `End` and `Wall clock` rows, then the `Total wall clock` row.

Then run the check before Step 4:

```bash
node ravintio-zero/scripts/build-log-check.mjs plan/current/build-log.md
```

Stop if it exits non-zero, in both run modes. Fix each phase it names, then rerun. A phase with no block needs a `Skipped: P{n}` line in the log. Never archive a log that fails.

### Step 4: Archive

1. Determine the archive path: `plan/_archive/{feature-id}-{YYYY-MM-DD}/`. If it exists, suffix `-2`, `-3`, and so on.
2. Search the repo for links pointing at `plan/current/...` (living docs, `docs/decisions-index.md`, `src/*/docs/`). Update each to the archive path.
3. Copy all of `plan/current/` to the archive path, then delete the `plan/current/` contents. Never use an atomic move.
4. `git add` everything: the archive, the deletions, and the link updates. Untracked artifacts must not be left behind. Check with `git status --porcelain` before committing.
   - In an active initiative, stage by explicit path: `plan/current/`, `plan/changelog/`, `plan/_archive/`, and each link update. Never stage a `plan/backlog/` entry the step did not write. The initiative skill queues those, and they stay untracked.

### Step 5: Build assessment

Read the archived `build-log.md`. It is now the only copy. Write `build-report.md` into the same archive folder:

- The run speed from the build-log header.
- Agent counts, model tiers, and wall-clock time per phase. A phase with no `End` row reads `not recorded`.
- Parallelism used, and multi-task phases that ran sequentially.
- Self-corrections, with whether each was avoidable.
- One improvement suggestion per phase where warranted.
- The postmortems the run wrote to `plan/postmortems/`, by path, or `Postmortems: none`.

Then run `node ravintio-zero/scripts/workflow-metrics.mjs "{archive-folder}"` and append its output to `build-report.md`. If it exits non-zero, write `Workflow governance: not measured ({reason})` instead. The reason is `build log unreadable` or `thresholds invalid`, never a path or error text. A breach does not stop ship in either run mode.

Source every metric from the build log. Never infer or fabricate. If routing or parallelism is not evidenced, treat it as not applied.

Last, run `ravintio-retrospective` in run mode. It writes the record to `plan/retrospectives/`. Append `Retrospective: {path}` to `build-report.md`, or `Retrospective: none` if the skill wrote no record. A missing retrospective never blocks ship.

### Step 6: Version bump

Derive the current product version with `node ravintio-zero/scripts/product-version.mjs`, then apply the release version to `docs/about.md`, `product.yml`, and `component.yml`. The version must match `[0-9]+\.[0-9]+(\.[0-9]+)?` and must not be lower than the last release tag. If it fails validation, ask the human for the value. Never tag a fabricated version.

### Step 7: Release tag

Create no tag. After the human merges the PR, the CI `release-tag` job tags the merge commit on `main` with `v{version}`. A squash merge leaves a branch tag off `main`. For an initiative step: I-D Advance tags the squash commit.

### Step 8: Clear sentinels

Read `plan/.run-mode` first and keep the value for Step 10. Delete `plan/.orchestrator-active`, `plan/.orchestrator-ack`, and `plan/.run-mode` if present. Also delete `plan/.run-speed` if present. Stage the deletions and commit. Confirm with `git ls-files` that none remain tracked.

Do this before any push, in every run mode and for both PR options, so no PR carries the sentinels.

### Step 9: PR

If a local-git-only override is active in `ravintio-overrides/instructions/`, skip the question and output the description block. Otherwise, follow the run mode.

In `gated`, ask the human:

```
P4 Ship: Version v{version} set. CI tags the merge commit on main.
Should I raise the PR, or will you?
  [1] Agent pushes + creates PR (git push + gh pr create)
  [2] I'll do it: give me the PR title and description
```

In `autonomous`, take option [1] without asking.

Title: `{feature-id}: {one-line summary}`. Body: summary bullets, key decisions, validation results, test plan. In `autonomous`, add an `## Acceptance evidence` section with the contents of the archived `acceptance-evidence.md`. Add the same `## Workflow governance` section from `build-report.md`, or the `Workflow governance: not measured ({reason})` line, in both run modes and for both PR options. A breach does not stop ship. PR bodies carry no AI attribution. Leave out `Generated with [Claude Code]` lines (with or without a robot emoji), `Co-Authored-By:` lines that name an AI tool, and `Claude-Session:` lines or claude.ai/code session links.

Before `gh pr create`, write the PR body to a temporary file and run `node ravintio-zero/scripts/check-attribution.mjs <file>` on it. If it fails, remove the attribution lines and rerun. If it still fails, stop in both run modes:

```
P4 Ship: Blocked: attribution line in the PR body.
```

Also scan the PR body for credential patterns, such as `ghp_`, `github_pat_`, `AKIA`, `sk-`, `xox`, and `-----BEGIN` private-key headers. If one matches, stop in both run modes, and never print the value:

```
P4 Ship: Blocked: possible credential in {path}. Remove it or confirm it is not a secret.
```

Use `the PR body` as `{path}`.

The sentinel commit from Step 8 comes first. In option [1], push the branch only, then raise the PR:

```bash
git push origin {branch}
gh pr create
```

In option [1], capture the PR number and URL, and update the changelog's `**PR:**` field.

In option [2], print the PR title and description. The human pushes the branch later. CI tags the merge commit on `main`. In the local-git-only case, also print the tag commands for the human to run on the merge commit after merging, or note that the CI `release-tag` job does it:

```bash
git tag v{version} -m "{feature-id}" {merge-commit}
git push origin v{version}
```

If a push or `gh pr create` fails, stop in both run modes. Report the exact error and do not retry with force:

```
P4 Ship: Blocked: {command} failed with {exact error}. Fix the remote or the credentials, then tell me to retry.
```

### Step 10: Final gate

In `gated`, this gate stops. Print:

```
P4 Ship: Complete: {feature-id} shipped.

Archive: plan/_archive/{feature-id}-{YYYY-MM-DD}/
Changelog: plan/changelog/{feature-id}-{YYYY-MM-DD}.md
Build report: plan/_archive/{feature-id}-{YYYY-MM-DD}/build-report.md
Tag: v{version} (CI tags the merge commit on main)
PR: {URL, or "see description above"}
```

In `autonomous`, print the same summary, then end the run with this line:

```
P4 Ship: Complete: PR #{n} ready for your review
```

Use the run mode read in Step 8, because Step 8 deletes `plan/.run-mode`. Merging the PR is human-only in every mode, no exception.

## Parallelism

Ship steps run in order, because most steps read the one before.

### Fast batch

When `plan/.run-speed` holds `fast`, run one batch after Step 4 in one message. It has two units with disjoint files:

1. Step 5, the build assessment, in a cheaper-tier subagent. It writes only `build-report.md` in the archive folder.
2. Step 6, the version bump, inline. It writes only `docs/about.md`, `product.yml`, and `component.yml`.

Each unit commits its own files by path, one commit at a time, per `## Fast batches` in `ravintio-zero/standards/agent-dispatch-standards.md`. Step 7 starts after both land. At `standard`, run Steps 5 and 6 in order.

## Initiative steps

When `plan/current-initiative/initiative.md` has `status: active`, read `ravintio-zero/standards/roadmap-standards.md` first. Step 9 gives way to its I-D Advance stage, and I-E Delivery follows the last step. Outside an initiative, ignore this section.

To merge the step PR, copy this plain line. Replace `{n}` with the literal PR number from the `gh pr create` output. Use no command substitution, variables, or pipes on the line, or `merge-guard` cannot confirm the squash and blocks it.

```bash
gh pr merge --squash --delete-branch {n}
```
