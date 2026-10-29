# RAVINTIO Zero - Mandatory Pipeline Rules

This project uses RAVINTIO Zero, a confirmed-design pipeline. These rules are non-negotiable and apply to every session.

## Hard Limits

1. **No code without a confirmed design.** You MUST NOT generate application code unless a confirmed design exists at plan/current/design.md. If none exists, load the ravintio-orchestrator skill and begin the discovery phase (P0). Do NOT skip to code generation.
2. **No code without documentation.** Every component MUST have a component.yml manifest and docs/ artifacts. Never produce code without its corresponding documentation.
3. **No direct schema modification.** Write a migration proposal at src/{component-id}/docs/migrations/proposed-{desc}.md and STOP for human approval.
4. **Destructive schema operations require human approval.** Drop column, drop table, rename - propose and stop. No exceptions.
5. **Data is owned by one component.** Never write to data owned by another component.
6. **No credentials in context.** If a credential appears anywhere, flag it immediately and do not use it.
7. **Update documentation after any deviation.** If implementation required deviating from the spec, plan, or design decisions, you MUST update the affected artifacts (plan/, docs/, or component.yml) to reflect what was actually built. Documentation must always match reality.

## Operational Directives

- **Be succinct:** Minimal prose. Format answers in markdown with brevity.
- **Commit messages and PR descriptions:** Never add `Co-Authored-By`, `Generated with [Claude Code]`, `Claude-Session:`, or any AI attribution. The `commit-msg` hook is **blocking**: it rejects AI attribution, affirmatory language, and >72-char subjects. Follow `ravintio-zero/standards/commit-standards.md`.
- **Do not invent APIs:** Only call endpoints that explicitly exist in the provided OpenAPI interfaces.

## Hook Enforcement

Setup installs enforcement hooks. When one blocks an action, read `ravintio-zero/standards/hook-enforcement.md`.

The `commit-msg` hook is blocking. It rejects commits that break `commit-standards.md`.

## Reply Conventions

Begin every reply in an active run with a prefix. Use the status form `{prefix} {Status}: {one-liner}`. The status is Starting, Resuming, Complete, Blocked, or Skipped.

| Prefix | Use for |
|--------|---------|
| `P0 Discovery:` | Discovery |
| `P1 Plan:` | Plan |
| `P2 Implement:` | Implement |
| `P3 Validate:` | Validate and accept |
| `P4 Ship:` | Ship |
| `I-A Chart:` | Initiative chart stage |
| `I-B Activate:` | Initiative activate stage |
| `I-C Run:` | Initiative run stage |
| `I-D Advance:` | Initiative advance stage |
| `I-E Delivery:` | Initiative delivery stage |

Use `Supervise:` for out-of-phase work. Examples are supervising an initiative driver, filing backlog entries, and answering questions while another session runs a step. It takes the same status form, as in `Supervise: Complete: {one-liner}`.

**Reporting rule.** A reply reports results, deviations, failures, and decisions the human must make. A reply never states that the agent followed a standing rule. The exception is a rule that blocked an action or a rule the agent departed from.

## Escalation

If you are blocked, unable to resolve tests after 5 attempts, or confused by conflicting requirements, **STOP**. Do not guess. State clearly what is blocking you and ask the human for direction.
