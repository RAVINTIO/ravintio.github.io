# The six tools

RAVINTIO has six tools. Each one works on its own, and none requires another. This page gives the purpose, the question, and the boundaries of each tool. For the name and shared principles, see [what is RAVINTIO](what-is-ravintio.md).

## At a glance

| Tool | Area | Status | The question it answers |
|------|------|--------|-------------------------|
| RAVINTIO Zero | Autonomous engineering | Available | How can we build this with minimal ceremony? |
| RAVINTIO Framework | Autonomous engineering | Available | How can we work within established governance requirements? |
| RAVINTIO Accept | Verification and assessment | In design | Is this change demonstrably fit for release? |
| RAVINTIO Qualify | Verification and assessment | In design | Does a skill meet its criteria, and does it still after changes? |
| RAVINTIO Insight | Verification and assessment | In design | What does the evidence say about risks and improvements? |
| RAVINTIO Unbound | Experimental research | In design, experimental research only | How does an agent behave when you give it only functional requirements? |

## How the tools relate

You can use any tool alone. If you use more than one, they fit together in these ways:

- Zero and Framework are alternatives. You pick the one whose governance depth suits your project.
- Accept can check a change from Zero, from Framework, or from any other process.
- Qualify checks agent skills, separately from any software release.
- Insight assesses a system and its practices, however the software was built.
- Unbound runs isolated experiments. It is never a route to production.

## RAVINTIO Zero

**Status:** Available

RAVINTIO Zero is a lightweight, governed workflow for autonomous engineering. It suits individuals, small teams, and straightforward projects. You set the boundaries, and the agent does the work inside them.

Zero answers this question: how can we build this with minimal ceremony?

**What it owns**

- Concise requirements, constraints, and acceptance criteria.
- An execution plan and persistent task state.
- The implement, test, debug, and refactor loop.
- Essential build, test, security, and quality checks.
- An evidence summary and a clear point where the agent hands back to you.

**What it doesn't replace**

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

**What it owns**

- Structured discovery and traceable requirements.
- Architectural boundaries, decision records, and component ownership.
- Threat modelling and security controls where they apply.
- Planning across components and integrations.
- Risk handling, approvals, and exception management.
- Persistent state, decision records, and recovery.

**What it doesn't replace**

- Your CI/CD pipelines, test tools, and security scanners.
- Your repositories and pull request workflows.
- Your monitoring and incident platforms.
- Your organisation's governance. Framework helps you apply it and never becomes a competing authority.

Find the code in the [RAVINTIO Framework repository](https://github.com/RAVINTIO/ravintio-framework).

## RAVINTIO Accept

**Status:** In design

RAVINTIO Accept is for independent acceptance. It traces a change from its functional requirement to the evidence that proves it. It works whoever or whatever built the change.

Accept answers this question: is this change demonstrably fit for release?

Its central idea is that an implementation claims it is done, and Accept asks where the evidence is. Accept keeps a missing check, a failed check, and a passed check apart.

**What it owns**

- Mapping requirements and acceptance criteria to evidence.
- Evaluating that evidence against policy.
- A result of accept, reject, or needs a human decision.

**What it doesn't replace**

- Your test frameworks, scanners, and CI/CD pipelines.
- Your test management and defect tracking.
- Your release governance and risk acceptance. Accept informs these decisions and doesn't make them for you.

Accept isn't an implementation engine.

## RAVINTIO Qualify

**Status:** In design

RAVINTIO Qualify is for evaluating agent skills. It checks a skill when you first adopt it. It checks again after the skill changes.

Qualify answers this question: does a skill meet its criteria, and does it still after changes?

**What it owns**

- Defined criteria for what a skill must do.
- Evaluation of a skill against those criteria.
- Re-evaluation after a skill changes.

**What it doesn't replace**

- Your software release acceptance. Qualify evaluates skills and not releases.
- Your own review of how a skill fits your work.

## RAVINTIO Insight

**Status:** In design

RAVINTIO Insight is for evidence-led assessment of software systems and engineering practices. It looks at architecture, security, reliability, testing, delivery, documentation, and AI workflows. It works the same way however the software was built, and it is read-only by default.

Insight answers this question: what does the available evidence indicate about risks and potential improvements?

Insight separates observation from inference. It states its uncertainty and names the evidence it couldn't see.

**What it owns**

- Evidence gathering and reproducible checks.
- Findings with severity, confidence, and evidence links.
- Recommendations for follow-up work.
- Support for blameless review of incidents.

**What it doesn't replace**

- Your monitoring and observability platforms.
- Your incident management.
- Your own decisions. Insight recommends changes and never makes them without your explicit permission.

## RAVINTIO Unbound

**Status:** In design, experimental research only

RAVINTIO Unbound is for research. It helps you study how models and agent skills behave when you supply only functional requirements. It leaves out prescribed practices such as upfront planning, architecture, and testing strategy. You can watch how decisions and outputs change over long autonomous runs.

Unbound answers this question: how does an agent behave when you give it only functional requirements?

Unbound is never for production software. It is not a development method. Experiments run in isolation, with independent observation and operator control.

**What it owns**

- Controlled, isolated experiments.
- Independent observation of agent behaviour.
- Comparison between models and skills.

**What it doesn't replace**

- Any route you use to build and ship real software. Use Zero or Framework for that.
