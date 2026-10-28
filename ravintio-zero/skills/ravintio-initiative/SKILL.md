---
name: ravintio-initiative
description: Coordinates an initiative from chart to delivery in the human's session. Charts the steps, activates the branch, starts the driver and a watch monitor, reports progress, queues backlog entries, and delivers the initiative PR. Never resumes or runs a step. Loaded when an initiative is active and the session is not a step session.
---

# RAVINTIO - initiative

> You coordinate an initiative the way the orchestrator coordinates a feature. You talk to the human. Step sessions run with no human present, and you never run one.

**Prefix.** Begin every reply with the stage prefix: `I-A Chart:`, `I-B Activate:`, `I-C Run:` while steps run, or `I-E Delivery:` for delivery and the final report. Use the form `{prefix} {Status}: {one-liner}`.

**Pack files.** Read `ravintio-zero/standards/roadmap-standards.md` first. Read `ravintio-zero/templates/initiative.template.md` before you write a plan.

## The three parts

| Part | Runs where | Owns |
|------|-----------|------|
| This skill | The human's session | I-A Chart, I-B Activate, reports, queue, I-E Delivery |
| Driver `ravintio-zero/scripts/initiative-run.mjs` | A background task you start | One step session after another, and the stop on a `Blocked:` line |
| `ravintio-orchestrator` | Each step session, a separate `claude -p` process | One feature from P0 to P4, then I-C Run and I-D Advance |

## Hard limits

1. Never run, resume, or edit a step. A step session owns `plan/current/`.
2. Never edit the working tree while the driver lock `plan/.initiative-runner.lock` is held.
3. Never merge into `main` and never commit to `main`. The human merges the initiative PR.
4. Write `plan/.initiative-ack` with your session id. Never write `plan/.orchestrator-ack`.
5. The hard limits of the orchestrator apply here too.

## Session start

1. Read the resume findings that the session start hook injected. If none are in context, run `node ravintio-zero/scripts/resume-detect.mjs`. If a finding reads `resume detection did not run`, check the files yourself.
2. If a `pending migration` finding names a migration whose `Applies when:` condition is true, run `ravintio-migrator` first.
3. Read `plan/current-initiative/initiative.md`. If no `initiative active` finding is present, offer I-A Chart and say whether an earlier initiative exists.
4. If the findings hold `initiative active` and `driver lock held`, report and start the monitor. Do not start a second driver.
5. If they hold `initiative active` and `driver lock free`, report the `initiative position` and offer to restart the driver.
6. If `position` is past the last step and `initiative.md` remains, run I-E Delivery.

## I-A Chart and I-B Activate

Follow the I-A Chart and I-B Activate sections of the roadmap standards. Take the human's confirmation per item. Chart builds the `## Decisions`, `## Baselines`, and `## Criteria` tables. At Activate, start two background tasks:

- The driver: `node ravintio-zero/scripts/initiative-run.mjs`.
- The monitor: `node ravintio-zero/scripts/initiative-watch.mjs`. It prints one line per event and a heartbeat every 5 minutes.

A host monitor expires after 30 minutes. Start a new one until the driver exits. If the host has no monitor tool, report on each prompt and at each phase end.

## Reports

Report at least every 5 minutes while the driver runs, at each phase end, and on request. Report an event at once when the build log gains a phase `Complete:`, `Blocked:`, or `Resolved:` line. When the build log changes to a new step, also report the `Complete:` lines already in it.

An interval report names:

- the step and its phase
- the last build log line and its age
- the commits since the last report
- any stop
- whether the driver still runs

While the step runs, the monitor also prints `I-C Run: activity:` lines, one per tool call, subagent start, or assistant text. Relay each one to the human at once, in the order received. Do not wait for the next interval report.

If nothing changed, say so and give the time since the last change. If the step keeps committing and its build log has not changed for 15 minutes, say the log is stale.

A progress report, on request and at each phase end, has two parts:

- **Initiative:** steps merged out of the total, backlog entries done out of the total, and a table of each step's feature, entries, version, and status.
- **Current step:** the phase, the progress within it, and what comes next. Progress is units done out of planned in P2, and criteria verified out of total from P3. Add highlights, such as what the step changes for the user, and any risk.

## Stops

If the driver prints `Blocked:` or exits non-zero, report the stop line and the step log path `plan/.initiative-logs/step-{position}.log`. Never resume the step. Ask the human how to proceed. After the human acts, offer to restart the driver.

## Backlog queue

While the lock is held, write each new backlog entry to `plan/.initiative-queue/{id}-{slug}/entry.md`. Reserve its id with `node ravintio-zero/scripts/reserve-id.mjs --commit`, which commits `plan/backlog/.next-id` alone at once. When a step merges and the driver is between steps or has exited, move the queued entries to `plan/backlog/` on the initiative branch. Commit each entry on its own. Never touch the queue while a step runs.

## I-E Delivery

After the driver exits, follow the I-E Delivery section of the roadmap standards. Then give the final report:

1. The initiative PR URL.
2. Each step with its version and tag.
3. The retrospective record path.
4. The stops that occurred and how each ended.
5. The backlog entries queued and where they now live.

Ask the human to merge the PR with a merge commit. Do not merge it yourself.
