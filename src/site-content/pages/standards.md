# Standards

This page lists the 18 standards files in the RAVINTIO Zero pack. They live in `ravintio-zero/standards/` in your installed project. Phase skills read them as rules, so agents follow the same conventions on every run.

Two subfolders sit beside these files. `library-standards/` holds per-language library guidance and `reference/` holds full stack evaluations. For the skills that read these files, see [skills](skills.md).

| Group | Files |
|-------|-------|
| Pipeline and governance | `agent-dispatch-standards.md`, `commit-standards.md`, `hook-enforcement.md`, `pack-update-policy.md`, `roadmap-standards.md`, `workflow-governance-standards.md` |
| Code and testing | `code-quality-standards.md`, `testing-standards.md`, `formatting-standards.md`, `language-quirks-en-gb.md` |
| Architecture and data | `api-design-standards.md`, `database-standards.md`, `monorepo-standards.md`, `stack-summary.md` |
| Build and operations | `build-target-standards.md`, `deployment-standards.md`, `infrastructure-standards.md`, `observability-standards.md` |

An initiative is a charted set of feature runs that share one branch and ship as one pull request. To chart one is to plan its steps with you. The driver is a script that starts each step in turn. A marker line is a log line in a fixed format, such as `Blocked:`, that a script counts.

## Pipeline and governance

These files govern how the pipeline itself behaves.

### `agent-dispatch-standards.md`

This file says which model tier each task uses. It also sets the rules for running subagents in parallel. The orchestrator and every phase skill that spawns subagents read it.

### `commit-standards.md`

This file sets the commit message format, `type(scope): short description`. It lists the allowed types and the rules the commit hook enforces. Agents read it before every commit.

### `hook-enforcement.md`

This file explains what each enforcement hook does and which hooks Codex runs. Read it when a hook blocks an action. Each block message points you to it.

### `pack-update-policy.md`

This file defines how Zero detects a pack update and how you confirm and trust it. Backlog entries cite it when they mention the pack update policy. The refresh and migration skills follow it.

### `roadmap-standards.md`

This file explains the five initiative stages. The initiative skill charts, activates, and delivers. The orchestrator runs each step. The ship skill advances it. The initiative, orchestrator, and ship skills point to it. Read it first when an initiative is involved.

### `workflow-governance-standards.md`

This file defines four workflow metrics, their marker lines, and the thresholds that count as a breach. A script counts the markers in a run folder. The gate reports a breach and never blocks.

## Code and testing

These files set the quality bar for the code and text agents write.

### `code-quality-standards.md`

This file describes what good code means in a RAVINTIO project. Agents write to the level of a strong senior engineer. The implement and refactor skills read it, and so do human reviewers.

### `testing-standards.md`

This file sets the test pyramid and the coverage each level needs. Every acceptance criterion becomes a test. The test writer and validate-and-accept skills read it.

### `formatting-standards.md`

This file sets the formats for dates and other details in project documents. Agents read it when they write plans, changelogs, and comments.

### `language-quirks-en-gb.md`

This file lists the deliberate exceptions to British English spelling. Agents never correct code identifiers, for example. Agents and humans check it before they correct any text.

## Architecture and data

These files guide design choices and the shape of the code base.

### `api-design-standards.md`

This file sets REST conventions such as status codes, versioning, pagination, and filtering. Agents read it when a component exposes an API.

### `database-standards.md`

This file covers schema design and migrations. It supports the rule that schema changes need a proposal and your approval. Agents read it when a component owns data.

### `monorepo-standards.md`

This file defines the directory structure for projects with several components. It shows where each component keeps its source, manifest, and docs.

### `stack-summary.md`

This file ranks backend stacks by how well agents work with them. Use it when you choose a stack during discovery. Full evaluations are in the `reference/` folder.

## Build and operations

These files cover how you build, ship, and watch the system.

### `build-target-standards.md`

This file defines the build target tiers. Agents read the explicit build target in the confirmed design and adjust their assumptions to match.

### `deployment-standards.md`

This file covers deployment strategy and environment configuration. Agents use the strategy declared in the operational model.

### `infrastructure-standards.md`

This file requires infrastructure as code and parameterised configuration. It sets where infrastructure files live in a component.

### `observability-standards.md`

This file requires structured logs, metrics, and traces in every component. It points to the library standards for the tools to use.
