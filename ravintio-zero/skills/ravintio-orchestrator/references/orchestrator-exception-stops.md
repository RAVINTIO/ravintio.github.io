# Orchestrator reference: exception stops

> Read this file when an exception stop applies or you write a Blocked line. The orchestrator `SKILL.md` points here from its Pack Index.

## Exception Stops

Both run modes stop on these exceptions. Commit all work and push it before the stop, where a push is authorised. The credential stop is the exception. It leaves the flagged file uncommitted and pushes nothing.

At each stop, follow these steps:

1. Append `Blocked: {exception} ({ISO-8601 timestamp})` to the build log under the current phase block, and commit it.
2. Print the message for the exception, then wait.
3. When the human acts, append `Resolved: {exception} ({ISO-8601 timestamp}, {decision})` to the build log, and commit it.
4. Run `ravintio-postmortem` for the stop, before ship.

After the human acts, the run resumes in the same mode from `plan/.run-mode`.

| Exception | Message |
|-----------|---------|
| A requirement or check still fails after 5 attempts | `P2 Implement: Blocked: {requirement or check} still fails after 5 attempts. Review the escalation and choose the next step.` (P3 uses `P3 Validate:`) |
| P2 needs a schema change, unless an initiative step matches a chart-approved row (see `ravintio-zero/standards/roadmap-standards.md`) | `P2 Implement: Blocked: schema change proposed at {path}. Approve or reject the migration proposal.` |
| The P3 security review finds an unmitigated critical or high issue | `P3 Validate: Blocked: {n} unmitigated critical or high security findings. Approve a mitigation or accept the risk.` |
| A push or `gh pr create` fails | `P4 Ship: Blocked: {command} failed with {exact error}. Fix the remote or the credentials, then tell me to retry.` (other phases use their own prefix) |
| A possible credential appears in a file the run will commit, or in a PR body | `{prefix} Blocked: possible credential in {path}. Remove it or confirm it is not a secret.` Stop before the commit and before any push. Never print the value. |
| P1 or P2 adds a library or service that is not on the approved list. This applies in every run mode. The list is the `Approved dependencies` field of `design.md` in a gated run, and the `## Dependencies` table of `initiative.md` in an initiative step | `{prefix} Blocked: new dependency {name} is not on the approved list. Approve it or choose an approved alternative.` When the human approves, add the name to the same list and record the decision in the `Resolved:` line. |

A fork that matches a `## Decisions` row is no stop (see I-C Run).

The status `Blocked:` follows the phase prefix, as in every status message. Never work round an exception stop. Do not force-push, merge, or skip the failing check.

