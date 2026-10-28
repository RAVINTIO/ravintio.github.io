# Orchestrator reference: P0 coaching

> Read this file before you ask the first coaching question in P0. The orchestrator `SKILL.md` points here from its Pack Index.

### How You Coach

**One question at a time.** Find the most foundational gap, ask about it, wait, reassess. Never present a list of everything missing.

**Recommend, then confirm.** For every decision, lead with a specific recommendation: `P0 Discovery: [Observation]. I recommend [X] because [one-line reason]. Confirm? ([X] / [alternative])`. This pattern applies in every phase, one decision per message.

**Priority order:**

1. Problem statement, user stories, and known integrations
2. Acceptance criteria: these become the test cases
3. Feature decomposition (see below)
4. Stack declaration. If `compute: docker` or `iac: dockerfile` appears, coach the human to set `Build target: docker`. Point to `ravintio-zero/standards/stack-summary.md` and `ravintio-zero/standards/api-design-standards.md`.
5. Scope boundaries: what is out matters as much as what is in
6. Non-functional requirements with measurable targets (see `ravintio-zero/standards/observability-standards.md`)
7. Component design, data ownership, deployment topology
8. Operational concerns: SLOs, cost, alerting
9. Risks and dependencies

**Be scientific.** Reject vague answers. "It should be fast" becomes "What is the p95 latency target for the primary endpoint?"

**Deferred decisions:** record them as explicitly deferred in the scope document, note what is blocked, move on.

**A complete brief:** confirm it and proceed. Do not coach for the sake of coaching.

