# Zero overview

RAVINTIO Zero is a pipeline that makes your coding agent plan before it writes code. You write a feature brief. The agent asks questions, produces a reviewable plan, and builds only what that plan describes. A pull request ends every run.

## Why Zero exists

Coding agents write code fast. The risk has moved from slow delivery to fast, plausible output that rests on unstated assumptions. Zero targets that risk with three ideas.

1. **The plan is the reviewable artefact.** When an agent writes the code, the prompt and plan largely decide the result. Zero makes the plan explicit, so you review decisions before code exists.
2. **Context lives with the component.** Each component keeps a manifest. Each feature keeps its plans and decision records. A later session, or a person, can read why the code looks the way it does.
3. **Gaps trigger questions.** If your brief leaves something open, the agent stops and asks. It does not fill the gap with a guess.

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

- The agent surfaces requirement gaps and resolves or defers them before it implements. It records each deferral in `plan/current/scope.md`.
- The agent never changes a data schema directly. It writes a migration proposal and waits for your approval.
- Destructive schema operations need your approval.
- One component owns each dataset. No component writes to another's data.
- Code and documentation are written together.
- Credentials stay out of the agent's context.

## Limits of Zero

Zero trades upfront effort for traceability. That trade does not always pay off.

- **Overhead is real.** A small change still runs all five phases. Prototypes and exploratory work may not repay the cost.
- **It depends on your review.** The pull request is a backstop only if you read the plans and the diffs. Zero structures the review. It cannot do the review for you.
- **A plan does not prevent every defect.** A complete specification reduces errors from assumptions. It does not guarantee correct code.
- **No benchmarks exist.** Nothing here measures outcomes with and without Zero.
- **It structures agent sessions, not teams.** Zero is not a project management method.
- **The parity check tests presence.** CI confirms that a file under `plan/`, `docs/`, or a `component.yml` changed beside `src/`. Reviewers check that the content matches the code.

## Next step

Follow [Install Zero](install-zero.md) to add the pack to a repository. For lists of what the pack contains, see [skills](skills.md), [standards](standards.md), and [templates](templates.md).
