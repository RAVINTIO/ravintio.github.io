# Templates

This page lists the 45 files in the RAVINTIO Zero templates folder. They live in `ravintio-zero/templates/` in your installed project. Skills copy a template when they write a document. Guides explain how to write the matching document.

For the skills that use these files, see [skills](skills.md). For where the documents land, see [pipeline](pipeline.md).

An initiative is a charted set of feature runs that share one branch and ship as one pull request. To chart one is to plan its steps with you.

| Group | Who writes it, and when |
|-------|-------------------------|
| Discovery and design | The orchestrator writes these before the plan phase |
| Plan phase | The plan skill writes these |
| Implement phase | The implement skill and the agents it calls write these |
| Validate and ship | The validate-and-accept and ship skills write these |
| Initiatives, records, and run control | Skills write these when a run pauses, parks, or finishes, or when work spans features |
| Project boot files | Setup copies these into your project |

## Discovery and design

The orchestrator writes these before the plan phase.

### `feature-brief.template.md`

The business case, scope, and product requirements for a feature. You write it, and the orchestrator reads it to coach you.

### `feature-brief-guide.md`

Explains how to write a feature brief that gives the orchestrator enough to coach you. Read it before you draft a brief.

### `discovery.template.md`

Records the raw findings of the discovery pass. The orchestrator creates it at P0, before the first coaching question.

### `design.template.md`

Holds the confirmed design, including the problem statement, the adoption mode, and the stack. Code generation waits until this file exists.

### `build-log.template.md`

The working record of a run. The orchestrator creates it at discovery and adds to it at each phase boundary.

## Plan phase

The plan skill writes these. See [pipeline](pipeline.md) for the phase order.

### `execution-plan.template.md`

Holds the non-functional requirements, an API and data summary, a test impact table, and the concurrency plan. It also indexes the requirement files, and each requirement traces to a user story or acceptance criterion.

### `execution-plan-guide.md`

Explains how the plan phase produces requirements and how to read them.

### `requirement.template.md`

Details one functional requirement and its acceptance criteria. The test writer turns each criterion into a test.

### `story-map.template.md`

Maps activities and steps to the requirement that covers each step. Gaps show up as missing requirements.

### `adr.template.md`

Records one architecture decision, its status, and its impact. The plan skill writes one per significant choice.

### `adr-guide.md`

Explains how the plan phase writes architecture decision records and how to read them.

### `scope.template.md`

States what is in scope and what is out. It keeps agents inside the agreed boundaries.

### `scope-guide.md`

Explains how to write a scope document that keeps agents within boundaries.

### `risk-register.template.md`

Tracks technical, operational, and security risks with their mitigations. The plan skill writes it and later phases update it.

### `risk-register-guide.md`

Explains how the plan skill and later phases find, assess, and track risks during a feature.

### `domain-glossary.template.md`

Defines the domain terms a feature uses. It keeps agents and humans using the same words.

### `domain-glossary-guide.md`

Explains how to maintain the shared vocabulary of a project.

### `cost-model.template.md`

Estimates the cost of running a feature. The plan skill fills it in when cost matters to the design.

### `operational-model.template.md`

Describes how you deploy and run a feature. Deployment standards point agents to the strategy it declares.

### `slo-definitions.template.md`

Defines the service level objectives for a feature. Observability work in later phases reads them.

## Implement phase

The implement skill and the agents it calls write these.

### `component.template.yml`

The manifest for one built component. Agents write it after building and read it before changing anything.

### `component-guide.md`

Explains the component manifest, when you create it, and what each field means.

### `data-contract.template.md`

Defines the schema and relationships of the data a component owns. Each data set has exactly one owner.

### `data-contract-guide.md`

Explains how the implement phase defines schema ownership and how migration proposals work.

### `iteration-log.template.md`

Logs what an agent session did. The implement skill writes it during the final documentation step.

### `iteration-log-guide.md`

Explains the audit trail that the implement phase writes at its end.

### `recommendations.template.md`

Lists improvements an agent spots but does not make. Any agent can add to it.

### `loop-state.template.md`

Stores the state of one loop so it survives context resets. The loop-runner skill defines how to use it.

### `loop-toggles.template.yml`

Switches individual loops on or off. Copy it to `ravintio-overrides/loop-toggles.yml` to change the defaults.

## Validate and ship

The validate-and-accept and ship skills write these.

### `test-report.template.md`

Reports which tests ran and how they ended. The validate-and-accept skill writes it at P3.

### `security-report.template.md`

Records the findings of the security review. The validate-and-accept skill writes it.

### `change-summary.template.md`

Summarises what an iteration achieved. You read it at the acceptance gate and in the pull request.

### `about.template.md`

Describes a feature and its version, with the date of its last update.

### `api-index.template.md`

Indexes the public API endpoints across all components. Omit it if no component has a public API.

### `architecture-overview.template.md`

Describes the current state of the system. The ship phase updates it in place after every run.

### `decisions-index.template.md`

Indexes the architecture decision records across all features. The ship phase updates it in place.

### `product.template.yml`

Holds the product-level version manifest. Every project needs `product.yml` with an `id`, because discovery stops without it. The extra fields, such as the component list, apply to products with several components.

## Initiatives, records, and run control

Skills write these when a run pauses, parks, or finishes, or when work spans features.

### `initiative.template.md`

Defines an initiative, which is a chain of feature steps you approve once. The initiative skill uses it. The driver is the script that starts each step in turn.

### `backlog-entry.template.md`

Records an item found during a run but left out of scope. The file-backlog skill writes it for later discovery.

### `pause.template.md`

Records the phase, active task, and last artefact when a run pauses. The orchestrator uses it to resume.

### `park.template.md`

Records why you parked a feature and where the branch stood. The orchestrator reads it to resume.

### `postmortem.template.md`

A blameless record of why a failure passed earlier phases. The postmortem skill fills it in.

### `retrospective.template.md`

A blameless review of a finished run or initiative, with the changes it files. The retrospective skill fills it in.

## Project boot files

Setup copies these into your project.

### `standard-boot.md`

The pipeline rules file for most AI tools. Setup copies it into your project as the instructions your tool reads every session.

### `codex-boot.md`

The same pipeline rules, written for Codex. Setup uses it when you install for that tool.
