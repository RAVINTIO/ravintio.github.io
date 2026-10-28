---
title: "Workflow governance standards"
summary: "Four workflow metrics, their marker lines, and the thresholds that decide a breach."
status: "active"
version: "0.1.0"
---
# Workflow governance standards

Read this file when you write a marker line or read a workflow governance section. The script `ravintio-zero/scripts/workflow-metrics.mjs` counts marker lines in a run folder and compares each count with a threshold. The gate reports and never blocks.

## Metrics

| Metric | Key | Writer |
|--------|-----|--------|
| Rework loops per requirement | `rework-per-requirement` | The implement and validate-and-accept skills |
| `Blocked:` stops | `blocked-stops` | Exception Stops in the orchestrator |
| Mid-pipeline design changes | `design-changes` | The mid-pipeline change reference |
| Human corrections at gates | `gate-corrections` | The orchestrator, at a gate in a gated run |

## Marker lines

- `Rework: REQ-{nnn}: {reason} ({ISO-8601 timestamp})`
- `Blocked: {exception} ({ISO-8601 timestamp})`
- `Requirement change: {cosmetic | additive | contradictory}: {what changed} ({ISO-8601 timestamp})`
- `Gate revised: P{N} ({ISO-8601 timestamp}, {what changed})`
- `Improve: REQ-{nnn}: cycle {n}: {finding}: {change}: suite {pass | fail, reverted} ({ISO-8601 timestamp})`
- `Improve: REQ-{nnn}: cycle {n}: no change worth making ({ISO-8601 timestamp})`

The implement skill writes the `Improve:` markers, one per improvement cycle. `workflow-metrics.mjs` does not count them, and no threshold applies. They record the gain for a human to read.

Write each marker line to `build-log.md`. A loop may also write markers to its `loop-state-*.md` file.

## Counting rule

A line counts as a marker when it starts with the marker text. Leading whitespace and one list marker (`- `, `* `, or `1. `) may come first. The script skips lines inside fenced code blocks (``` or ~~~). A mention in prose does not count.

For rework, the script counts markers per requirement id. The report shows the highest count and the requirement that holds it.

## Thresholds

A metric breaches when its value is greater than its threshold. The script reads the table by the `Key` column. Each threshold must be a whole number.

| Metric | Key | Threshold |
|--------|-----|-----------|
| Rework loops per requirement (highest) | rework-per-requirement | 2 |
| `Blocked:` stops | blocked-stops | 1 |
| Mid-pipeline design changes | design-changes | 1 |
| Human corrections at gates | gate-corrections | 2 |

## Report-only gate

The gate reports a breach and never blocks. The script exits 0 whenever it reads the build log and this table. It exits 1 if the build log is missing or a threshold key is missing or invalid. It exits 2 on a usage error.

## How ship uses the section

1. Step 5 runs the script on the run folder and adds the output to the build report.
2. Step 9 adds the same section to the PR body.
3. If the script fails, write `Workflow governance: not measured ({reason})` in both places. A script failure does not stop ship.
