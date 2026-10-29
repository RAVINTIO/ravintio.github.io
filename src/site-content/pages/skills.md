# Skills

This page lists the 16 skills in the RAVINTIO Zero pack. They live in `ravintio-zero/skills/` in your installed project. Each skill is a folder with a `SKILL.md` file that your AI tool loads when the task needs it.

For how the phases fit together, see [pipeline](pipeline.md). For the standards the skills follow, see [standards](standards.md).

| Group | Skills |
|-------|--------|
| Pipeline phases | `ravintio-orchestrator`, `ravintio-plan`, `ravintio-implement`, `ravintio-validate-and-accept`, `ravintio-ship` |
| TDD cycle | `ravintio-test-writer`, `ravintio-implementer`, `ravintio-refactor`, `ravintio-loop-runner` |
| Initiatives and records | `ravintio-initiative`, `ravintio-file-backlog`, `ravintio-postmortem`, `ravintio-retrospective` |
| Pack maintenance | `ravintio-migrator`, `ravintio-refresh-setup`, `ravintio-optimise-agent` |

## Pipeline phase skills

These skills carry a feature from brief to pull request. The orchestrator calls the other four in order.

### `ravintio-orchestrator`

This skill runs discovery and routes the work through the pipeline. It coaches you from a feature brief to a confirmed design. It then calls the plan, implement, validate-and-accept, and ship skills in turn. Your tool loads it first in every session. It also calls the migrator when it finds pending migrations.

### `ravintio-plan`

This skill writes the plan-phase documents. They cover requirements, architecture decision records, scope, risks, and a glossary. You review them all at one human gate. The orchestrator calls it after the design is confirmed.

### `ravintio-implement`

This skill builds each requirement with its tests and documentation together. It drives the TDD loop by calling the test-writer, implementer, and refactor skills. The orchestrator calls it during the implement phase.

### `ravintio-validate-and-accept`

This skill checks the finished work. It runs CI, reviews security, and verifies the code by running it. It then presents the acceptance gate for you to approve. The orchestrator calls it after implementation.

### `ravintio-ship`

This skill closes a run. It archives the plan, assesses the build, writes the changelog, sets the version, and prepares the pull request. It stops at a final gate for your approval. The orchestrator calls it last.

## TDD skills

These skills run inside the implement phase. Each handles one step of the red, green, refactor cycle.

### `ravintio-test-writer`

This skill is the red step. It writes one failing test for each requirement and confirms the test fails. The implement skill calls it before any code exists for that requirement.

### `ravintio-implementer`

This skill is the green step. It writes the least code that makes the failing test pass and confirms the test passes. The implement skill calls it after the test writer confirms a failure.

### `ravintio-refactor`

This skill is the refactor step. It improves the code quality and keeps every test passing. The implement skill calls it once the implementer confirms a pass.

### `ravintio-loop-runner`

This skill defines how every pipeline loop works. It sets the state file format, the stop rules, the escalation format, and the toggle protocol. Phase agents load it when they enter a loop. You don't call it yourself.

## Initiative and record skills

These skills support work that spans several features, and the records you keep after a run.

### `ravintio-initiative`

This skill coordinates an initiative from chart to delivery in your own session. It charts the steps, activates the branch, starts the driver, and reports progress. It also delivers the initiative pull request. It never runs a step itself. Your tool loads it when an initiative is active and the session is not a step session.

### `ravintio-file-backlog`

This skill files one backlog entry in another repository. It finds or creates the backlog folder, reserves the next id, and writes the entry. It leaves that repository's git state alone. You invoke it on request, for example "file a backlog entry in my-repo".

### `ravintio-postmortem`

This skill writes a blameless postmortem for a failure. Triggers include a failed CI run, a blocked stop, an escaped defect, or your request. It builds a timeline and a 5 whys chain, files each action, and saves the record under `plan/postmortems/`. The orchestrator calls it, or you ask for it.

### `ravintio-retrospective`

This skill writes a blameless retrospective for a shipped run or a delivered initiative. It records what helped, what slowed the work, and what to try next. The ship skill calls it after the build report. You can also ask for it.

## Pack maintenance skills

These skills look after the installed pack rather than a feature.

### `ravintio-migrator`

This skill applies a pending RAVINTIO Zero migration. It reads the migration file, shows you the findings, applies the changes you confirm, and archives the migration. The orchestrator calls it when it detects pending migrations.

### `ravintio-refresh-setup`

This skill refreshes an install. It detects your target tool, recovers the flags you used before, and confirms them with you. It then runs the setup script again with those flags. You invoke it on request, for example "refresh the RAVINTIO setup".

### `ravintio-optimise-agent`

This skill reviews the skills folder for content that no longer earns its place. It offers one suggestion at a time and waits for your decision. It never edits files. You invoke it on request.
