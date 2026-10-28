# Orchestrator reference: run speed

> Read this file before you ask the run-speed question, restore a speed on resume, or clear the speed file. The orchestrator `SKILL.md` points here from its Pack Index.

## Run-speed question

Ask this question after the run-mode question in Design Confirmation:

```
How fast should the agent run P1 to P4?

  [1] Standard: each phase decides its own batches
  [2] Fast: each phase dispatches its listed fast batch in one message
```

Write the answer to `plan/.run-speed` (`standard` or `fast`). Append `Run speed: {fast | standard} ({ISO-8601 timestamp})` to the build log under the P0 block, and include both in the discovery commit.

- A missing `plan/.run-speed` counts as `standard`.
- A value other than `fast` or `standard` also counts as `standard`, and the build log names that value.
- `plan/.run-mode` keeps its two values. The speed never goes into it.

Phases still run in order at either speed, and every gate and exception stop stays in place. The rules for a fast batch are in `## Fast batches` of `ravintio-zero/standards/agent-dispatch-standards.md`. Each phase skill lists its own units under `### Fast batch`.

## Initiative step

An initiative step asks no run-speed question. It writes the initiative's `**Speed:**` field to `plan/.run-speed`, as I-C Run in `ravintio-zero/standards/roadmap-standards.md` describes. If the field is absent or holds another value, it writes `standard`.

## Resume

On resume, read `plan/.run-speed` and keep that speed without asking.

## Cleanup

These steps delete `plan/.run-speed` along with the other sentinels:

- The interrupted-ship cleanup in Resume Detection.
- The stale run-mode check in Discovery Start Actions.
- Ship Step 8.
