# The six tools

RAVINTIO has six tools. Each one works on its own, and none requires another. This page gives the purpose, the question, and the boundaries of each tool. For why to use RAVINTIO and its shared principles, see [what is RAVINTIO](what-is-ravintio.md).

## At a glance

| Tool | Area | Status | The question it answers |
|------|------|--------|-------------------------|
| <span class="tool-name">RAVINTIO<br>Zero</span> | Autonomous engineering | Available | How can we build this with minimal ceremony? |
| <span class="tool-name">RAVINTIO<br>Framework</span> | Autonomous engineering | Available | How can we work within established governance requirements? |
| <span class="tool-name">RAVINTIO<br>Accept</span> | Verification and assessment | In design | Is this change demonstrably fit for release? |
| <span class="tool-name">RAVINTIO<br>Qualify</span> | Verification and assessment | In design | Does a skill meet its criteria, and does it still after changes? |
| <span class="tool-name">RAVINTIO<br>Insight</span> | Verification and assessment | In design | What does the evidence say about risks and improvements? |
| <span class="tool-name">RAVINTIO<br>Unbound</span> | Experimental research | In design | How does an agent behave when you give it only functional requirements? |

## How the tools relate

You can use any tool alone. If you use more than one, they fit together in these ways:

- Zero and Framework are alternatives. You pick the one whose governance depth suits your project.
- Accept is designed to check a change from Zero, from Framework, or from any other process.
- Qualify is meant to check agent skills, separately from any software release.
- Insight is meant to assess a system and its practices, however the software was built.
- Unbound is designed to run isolated experiments. It is never a route to production.

## RAVINTIO Zero

**Status:** Available

RAVINTIO Zero is a lightweight, governed workflow for autonomous engineering. It suits individuals, small teams, and straightforward projects. You set the boundaries, and the agent does the work inside them.

Zero answers this question: how can we build this with minimal ceremony?

**What it does**

- Concise requirements, constraints, and acceptance criteria.
- An execution plan and persistent task state.
- The implement, test, debug, and refactor loop.
- Essential build, test, security, and quality checks.
- An evidence summary and a clear point where the agent hands back to you.

**What it works alongside**

- Your CI/CD pipelines and deployment tools.
- Your test frameworks, static analysis, and security scanners.
- Your repositories, version control, and pull request flow.
- Your organisation's own governance and approval processes.

Zero uses the output of these systems as evidence. It doesn't provide the deep traceability of Framework, or independent acceptance, skill evaluation, or system assessment.

Start with the [Zero overview](zero-overview.md). The code lives in the [RAVINTIO Zero repository](https://github.com/RAVINTIO/ravintio-zero).

## RAVINTIO Framework

**Status:** Available

RAVINTIO Framework is a structured workflow for autonomous engineering. It fits multi-team, security-sensitive, or traceability-intensive projects. Framework isn't Zero with more power. Both aim for high autonomy, and they differ in how deep and explicit the governance is.

Framework answers this question: how can we work within established governance requirements?

**What it does**

- Structured discovery and traceable requirements.
- Architectural boundaries, decision records, and component ownership.
- Security controls where they apply.
- Planning across components and integrations.
- Risk handling, approvals, and exception management.
- Persistent state, decision records, and recovery.

**What it works alongside**

- Your CI/CD pipelines, test tools, and security scanners.
- Your repositories and pull request workflows.
- Your monitoring and incident platforms.
- Your organisation's governance. Framework helps you apply it and never becomes a competing authority.

Find the code in the [RAVINTIO Framework repository](https://github.com/RAVINTIO/ravintio-framework).

## RAVINTIO Accept

**Status:** In design

RAVINTIO Accept is meant for independent acceptance. It is designed to trace a change from its functional requirement to the evidence that proves it. The intent is that it works whoever or whatever built the change.

Accept is designed to answer this question: is this change demonstrably fit for release?

Its central idea is that an implementation claims it is done, and Accept asks where the evidence is. Accept is designed to keep a missing check, a failed check, and a passed check apart.

**What it does**

- Mapping requirements and acceptance criteria to evidence.
- Evaluating that evidence against policy.
- A result of accept, reject, or needs a human decision.

**What it works alongside**

- Your test frameworks, scanners, and CI/CD pipelines.
- Your test management and defect tracking.
- Your release governance and risk acceptance. Accept is designed to inform these decisions and never make them for you.

Accept is not meant to be an implementation engine.

## RAVINTIO Qualify

**Status:** In design

RAVINTIO Qualify is meant for evaluating agent skills. It is designed to check a skill when you first adopt it and again after the skill changes.

Qualify is designed to answer this question: does a skill meet its criteria, and does it still after changes?

**What it does**

- Defined criteria for what a skill must do.
- Evaluation of a skill against those criteria.
- Re-evaluation after a skill changes.

**What it works alongside**

- Your software release acceptance. Qualify is meant to evaluate skills and not releases.
- Your own review of how a skill fits your work.

## RAVINTIO Insight

**Status:** In design

RAVINTIO Insight is meant for evidence-led assessment of software systems and engineering practices. It is designed to look at architecture, security, reliability, testing, delivery, documentation, and AI workflows. The intent is that it works the same way however the software was built, and that it stays read-only by default.

Insight is designed to answer this question: what does the available evidence indicate about risks and potential improvements?

Insight is meant to separate observation from inference. It is designed to state its uncertainty and name the evidence it couldn't see.

**What it does**

- Evidence gathering and reproducible checks.
- Findings with severity, confidence, and evidence links.
- Recommendations for follow-up work.
- Support for blameless review of incidents.

**What it works alongside**

- Your monitoring and observability platforms.
- Your incident management.
- Your own decisions. Insight is meant to recommend changes and never make them without your explicit permission.

## RAVINTIO Unbound

**Status:** In design

RAVINTIO Unbound is meant for research. It is designed to help you study how models and agent skills behave when you supply only functional requirements. It leaves out prescribed practices such as upfront planning, architecture, and testing strategy. The aim is to watch how decisions and outputs change over long autonomous runs.

Unbound is designed to answer this question: how does an agent behave when you give it only functional requirements?

Unbound is never for production software. It is not a development method. Experiments are meant to run in isolation, with independent observation and operator control.

**What it does**

- Controlled, isolated experiments.
- Independent observation of agent behaviour.
- Comparison between models and skills.

**What it works alongside**

- Any route you use to build and ship real software. Use Zero or Framework for that.
