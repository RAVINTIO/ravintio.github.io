# What is RAVINTIO?

RAVINTIO lets a coding agent do real engineering work on its own while you keep control of what ships. It's a set of open-source tools. RAVINTIO Zero and RAVINTIO Framework are available now.

## Why use RAVINTIO?

Coding agents write code fast. RAVINTIO makes that code something you can trust, review, and maintain.

- **Changes are designed before they're built.** The agent works from a design and requirements you confirm. It builds against them and no further.
- **Work follows your standards.** Code, tests, commits, and docs follow the same standards on every change. Hooks block commits and actions that break your rules.
- **Documentation comes with the code.** Every component gets the same set of docs: purpose, interface, dependencies, risks, and test coverage. Project-wide docs stay current with each change.
- **Architectural decisions are on record.** Each significant choice gets a decision record. The record states the context, the options, and the consequences, good and bad.
- **Constraints hold.** The agent uses only the dependencies you approved, and it stays inside the boundaries you set. Outside them, it stops and asks you.
- **Solutions stay as simple as the problem allows.** The agent builds what the requirements ask for and no more. It writes the minimum code to pass each test, then looks for a simpler version. Unneeded layers, unused code, and speculative features never reach your codebase. They would become someone's maintenance burden later.
- **Done means proven.** The agent runs the tests, the checks, and the software itself before it hands back. The pull request carries the evidence.
- **Failures get fixed, not reported.** The agent diagnoses build, test, and security failures and repairs them before it escalates.
- **Work survives a new session.** Plans, decisions, and progress live in plain files in your repo. Work resumes where it stopped.
- **No lock-in.** RAVINTIO works with your own CI, version control, and pull request flow. It adds no service to run.

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
- **Assessment challenges the work.** Acceptance and review don't trust a self-report.
- **Learning is blameless.** Reviews look at systems and conditions, not at individuals.

## The tools work independently

Each tool is meant to work on its own. None of them requires another to be installed.

You can combine them if it helps. RAVINTIO Accept is designed to check a change from any source, including a change built with Zero. RAVINTIO Insight is designed to assess a system however its developers built it. These links are optional.

## Where to go next

- Read [the six tools](six-tools.md) to compare the tools and choose one.
- Read [the Zero overview](zero-overview.md) to get started with RAVINTIO Zero.
