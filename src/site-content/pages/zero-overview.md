# Zero overview

RAVINTIO Zero is a pipeline that makes your coding agent plan before it writes code. You write a feature brief. The agent asks questions, produces a reviewable plan, and builds only what that plan describes. A run ends in a pull request unless you pause, park, or stop it.

## Why use Zero

Zero gives you the benefits in [why use RAVINTIO](what-is-ravintio.md#why-use-ravintio) with low ceremony. These reasons are specific to Zero.

- **You review the plan before code exists.** The agent writes a design and a plan, and you confirm both. You catch a wrong assumption while it costs a comment, not a rewrite.
- **Gaps become questions, not guesses.** If your brief leaves something open, the agent stops and asks you.
- **Context lives with the component.** Each component keeps a manifest. Each feature keeps its plans and decision records. A later session, or a person, can read why the code looks the way it does.
- **Every change takes the same route.** A small change makes a small run, and the gates stay. You always know where a run stands.
- **It runs in the tools you already use.** Zero installs into your repo as plain files for Claude Code or Codex. It adds no service to run.

## How a run flows

Every change takes the same route through five phases. A small change makes a small run, with fewer requirements and shorter artefacts. The gates stay.

| Phase | Prefix | What happens |
|-------|--------|--------------|
| P0 Discovery | `P0 Discovery:` | The agent reads your brief, asks questions, and proposes a design for you to confirm. |
| P1 Plan | `P1 Plan:` | The agent writes requirements, scope, risks, a glossary, and decision records. |
| P2 Implement | `P2 Implement:` | Code, tests, and documentation land together. |
| P3 Validate | `P3 Validate:` | CI checks and a security review run, then you accept the result. |
| P4 Ship | `P4 Ship:` | The agent archives the plan, writes a changelog, and raises the pull request. |

Every agent reply starts with the phase prefix, so you always know where the run stands. See [the pipeline](pipeline.md) for the full detail.

## How Zero keeps solutions simple

Complexity that nobody asked for becomes a cost you pay on every later change. Zero works against it at each stage.

- **Discovery** sizes each release. If the work is too large for one run, the agent recommends a split.
- **Plan** derives requirements from your stories only. The agent never invents a requirement. Each decision record must state the downsides of a choice as well as the gains.
- **Implement** writes the minimum code to pass each test. An improvement loop then asks whether a simpler solution passes the same tests.
- **Standards** favour clarity over cleverness and code you can delete without side effects. They name over-abstraction and unused code as faults to remove.

## Who decides what

You act as product owner and architect. The agent acts as implementer inside the limits you set.

| You decide | The agent does |
|------------|----------------|
| What to build and why | Asks questions until the context is complete |
| The architecture, stack, and data ownership | Drafts the design and the plan for your review |
| The scope, including what is out | Writes code, tests, and documentation to match |
| Whether to run gated or autonomous | Runs checks and fixes failures, up to a limit |
| Whether to accept the result | Raises the pull request |
| Whether to merge | Never merges into `main` |

## Supported agent tools

Setup supports two tools.

| Tool | Setup argument | Boot file | Enforcement |
|------|----------------|-----------|-------------|
| Claude Code | `claude-code` | `CLAUDE.md` | The full set of enforcement hooks |
| Codex | `codex` | `AGENTS.md` | One hook, `merge-guard`. `AGENTS.md` states the other rules as instructions. |

Both tools get the same pipeline skills and the same git hooks. See [project operations](project-operations.md) for what the hooks enforce.

## Hard limits

These rules hold in every run, whatever the model or configuration.

1. No code without a confirmed design. The agent writes no application code until `plan/current/design.md` exists.
2. No code without documentation. Every component has a `component.yml` manifest and `docs/` artefacts.
3. No direct schema modification. The agent writes a migration proposal and waits for your approval.
4. Destructive schema operations need your approval. That covers dropping a column or table, and renaming.
5. One component owns each dataset. No component writes to another's data.
6. No credentials in context. If one appears, the agent flags it and does not use it.
7. Update documentation after any deviation. The agent changes the plan, docs, or manifest to match what it built.

## When Zero fits

Zero suits changes you will maintain. It trades some upfront effort for a record of why the code looks the way it does.

- **Code that lives on.** A product, service, or library that others will change later repays the plan and the records.
- **Work you review.** The pull request carries the plans, the decisions, and the evidence. Zero structures the review, and you still do it.
- **Agent sessions.** Zero structures how an agent works on a change. It works alongside your team's planning method.

CI confirms that a file under `plan/`, `docs/`, or a `component.yml` changed beside `src/`. You confirm that the content matches the code.

A throwaway prototype or a quick experiment may not need Zero. Every change runs all five phases, however small.

## Next step

Follow [Install Zero](install-zero.md) to add the pack to a repository. For lists of what the pack contains, see [skills](skills.md), [standards](standards.md), and [templates](templates.md).

## Terms

These terms appear throughout the guide.

- **Orchestrator:** The skill that runs discovery and routes the run through the phases. It loads at the start of a session.
- **Phase:** One of the five steps of a run, from P0 to P4. Each phase has its own skill and output.
- **Gate and gated run:** A gate is a stop where you review before the next phase starts. In a gated run the agent stops at every gate.
- **Boot file:** The file the agent tool reads at session start, `CLAUDE.md` or `AGENTS.md`. Setup generates it.
- **Sentinel:** A small marker file in `plan/` that tells the hooks a run is active. Ship deletes them.
- **Build log:** The record of a run in `plan/current/build-log.md`. It holds decisions, stops, and resolutions.
- **Parity check:** A check that a file under `plan/`, `docs/`, or a `component.yml` changed beside `src/`. It tests presence, not content.
- **Improvement loop:** A review cycle after the first green build of a requirement. It runs up to two cycles per requirement.
