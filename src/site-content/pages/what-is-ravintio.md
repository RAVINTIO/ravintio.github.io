# What is RAVINTIO

RAVINTIO is a family of six open-source tools for working with AI agents on software. Two are available now, and four are in design. The tools cover autonomous engineering, verification and assessment, and experimental research. Each tool is meant to work on its own.

## The name

RAVINTIO is an abbreviation. Each letter stands for a quality that responsible autonomous engineering needs. Always write RAVINTIO in block capitals.

| Letter | Quality | What it means for you |
|--------|---------|-----------------------|
| R | Resilience | Agents diagnose routine failures, recover, and keep making progress. |
| A | Autonomy | Agents work independently inside boundaries that you approve. |
| V | Vigilance | The tools watch for risk, falling quality, and unmet expectations. |
| I | Intelligence | Agents investigate and reason before they make an engineering decision. |
| N | Neutrality | The tools avoid favouring one implementation, agent, or earlier conclusion. |
| T | Transparency | Decisions, evidence, limits, and progress stay open to inspection. |
| I | Ingenuity | Agents try safe alternatives before they escalate a routine obstacle. |
| O | Optimisation | Outcomes, efficiency, and practices improve without weakening safeguards. |

## The three areas

The six tools sit in three areas. The areas describe purpose. They do not describe an order of use.

| Area | Tools | Purpose |
|------|-------|---------|
| Autonomous engineering | RAVINTIO Zero, RAVINTIO Framework | Build software with different levels of governance. |
| Verification and assessment | RAVINTIO Accept, RAVINTIO Qualify, RAVINTIO Insight | Check software changes, agent skills, and software systems. |
| Experimental research | RAVINTIO Unbound | Study how models and skills behave without prescribed engineering practices. |

Zero and Framework are alternative approaches to the same job. You choose one or the other. Zero keeps ceremony low. Framework adds structure for projects that need stricter governance.

## Shared design principles

Every tool follows the same ideas.

- **Humans keep authority over consequential decisions.** You decide intent, scope, risk, acceptance, and release.
- **Agents act within explicit boundaries.** Routine choices and recoverable failures don't need a human prompt.
- **Agents investigate before they escalate.** They read approved artefacts, existing code, and repository conventions first.
- **Agents repair before they stop.** They diagnose and fix build, test, and security failures where policy allows.
- **Work continues while it makes progress.** A retry count is never the only reason to stop.
- **Execution state is durable.** Work survives a reset of the context window or an interrupted session.
- **Evidence beats assertion.** An agent saying it has finished is not proof that it has.
- **Assessment challenges the work.** Acceptance and review don't trust a self-report.
- **Learning is blameless.** Reviews look at systems and conditions, not at individuals.
- **Artefacts are portable and reversible.** Plain text, explicit contracts, and controlled changes keep lock-in low.

## The tools work independently

Each tool is meant to work on its own. None of them requires another to be installed.

You can combine them if it helps. RAVINTIO Accept is designed to check a change from any source, including a change built with Zero. RAVINTIO Insight is designed to assess a system however its developers built it. These links are optional.

## Where to go next

- Read [the six tools](six-tools.md) to compare the tools and choose one.
- Read [the Zero overview](zero-overview.md) to get started with RAVINTIO Zero.
