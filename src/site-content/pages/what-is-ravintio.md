# What is RAVINTIO?

RAVINTIO is a set of six open-source tools for visibility and governance over agentic software development. RAVINTIO Zero and RAVINTIO Framework are available now. The other four tools are in design.

## Why RAVINTIO?

Agents now design, write, test, and change software. That work moves fast, and much of it happens out of sight. You need to see what an agent did and why. You also need to keep authority over what ships. RAVINTIO serves both needs.

- **You see what the agent did.** Plans, decisions, and evidence live in plain files you can read.
- **You see why.** Each significant choice carries a record of its context and the options it weighed.
- **You decide what ships.** People set intent, scope, risk, and release. Agents work inside those limits.
- **Evidence backs every claim.** A change counts as done when checks prove it, not when an agent says so.
- **You keep your own tools.** RAVINTIO works with your CI, version control, and review flow.

## The six tools

Each tool serves visibility, governance, or both.

### RAVINTIO Zero

Zero offers a lightweight, governed workflow for individuals and small teams. The agent builds only what a confirmed design and plan describe. Each run ends with an evidence summary and hands control back to you.

### RAVINTIO Framework

Framework offers a structured workflow for projects that need stricter governance. Traceable requirements and decision records show how each change came about. Component ownership and explicit approvals keep people in charge of risk.

### RAVINTIO Accept

Accept aims to give independent acceptance of any change, whoever built it. Its design traces each requirement to the evidence that proves it. The design ends in one of three results: accept, reject, or ask a person to decide.

### RAVINTIO Qualify

Qualify aims to evaluate agent skills against defined criteria. Its design calls for a check when you adopt a skill and again after the skill changes. You then know whether a skill still does what you expect.

### RAVINTIO Insight

Insight aims to assess a software system and its engineering practices from evidence. It aims to report findings with severity, confidence, and links to that evidence. Its design keeps it read-only by default. It aims to change nothing without your permission.

### RAVINTIO Unbound

Unbound aims to show how agents behave when they get only functional requirements. Its design runs each experiment in isolation, under independent observation and operator control. Unbound is never a route to production.

## The three areas

The six tools sit in three areas. The areas describe purpose, not an order of use.

| Area | Tools | Purpose |
|------|-------|---------|
| Autonomous engineering | RAVINTIO Zero, RAVINTIO Framework | Build software with different levels of governance. |
| Verification and assessment | RAVINTIO Accept, RAVINTIO Qualify, RAVINTIO Insight | Check software changes, agent skills, and software systems. |
| Experimental research | RAVINTIO Unbound | Study how models and skills behave without prescribed engineering practices. |

Zero and Framework are alternative approaches to the same job. You choose one or the other. Zero keeps ceremony low. Framework adds structure for projects that need stricter governance.

## Shared design principles

Every tool follows the same ideas.

- **Humans keep authority over consequential decisions.** You decide intent, scope, risk, acceptance, and release.
- **Assessment challenges the work.** Acceptance and review don't trust a self-report.
- **Learning is blameless.** Reviews look at systems and conditions, not at individuals.

## The tools work independently

No tool requires another. You can combine them if it helps. Accept aims to check a change from any source, including Zero. Insight aims to assess a system however its developers built it.

## Where to go next

- Read [the six tools](six-tools.md) to compare the tools and choose one.
- Read [the Zero overview](zero-overview.md) to get started with RAVINTIO Zero.
