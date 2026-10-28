# Orchestrator reference: P0 gate

> Read this file before you present the design for confirmation. The orchestrator `SKILL.md` points here from its Pack Index.

### Discovery Gate Checklist

Before presenting the design for confirmation, verify:

- [ ] Problem statement is specific and names the target user
- [ ] At least one user story in "As a / I / so that" format, full text
- [ ] Stack fully declared, no "TBD"
- [ ] Every component named with a single responsibility
- [ ] Every dataset maps to exactly one owning component
- [ ] Scope has in, out, and deferred sections ("Nothing deferred" is valid)
- [ ] At least one NFR has a measurable target
- [ ] Security section names auth strategy and data classification
- [ ] Risks section has at least one entry with likelihood and impact
- [ ] Multi-component: dependency order stated. Waved: waves grouped with rationale
- [ ] Adoption mode confirmed, or assumed standard-iterative as the only signal
- [ ] Version confirmed, not lower than the last known version
- [ ] Scope Lock Challenge complete, all four paths in the build log
- [ ] `discovery.md` exists and is complete (Hard Limit 12)
- [ ] Feature id follows `{0000000}-{kebab-case-name}`

Coach the human on any unchecked item before proceeding. Completeness loop (toggle `discovery_completeness`, default off): when enabled, this checklist is the loop's pass condition per `ravintio-loop-runner`. If the same item fails after 2 rounds, emit `P0 Discovery: Blocked: {item}` with escalation context.

### Design Confirmation (the discovery gate)

Read `ravintio-zero/templates/design.template.md`, then write `plan/current/design.md`. After human confirmation the design is immutable for the run: changes go through the mid-pipeline change protocol.

Before asking for confirmation, ask the run-mode question:

```
How should the agent run P1 to P4?

  [1] Gated: the agent stops for you at the end of each phase
  [2] Autonomous: the agent runs to a raised PR and stops only for escalations
```

Record the answer and write `plan/.run-mode` (`gated` or `autonomous`). No other value is valid. Append `Run mode: {gated | autonomous} ({ISO-8601 timestamp})` to the build log under the P0 block. Include it in the discovery commit. Only this skill writes `plan/.run-mode`. Phase skills read it and never write it. In gated mode, append `Gate accepted: P{N} ({ISO-8601 timestamp})` to the build log at each confirmed gate.
On a gate change, append `Gate revised: P{N}`.

Then ask the run-speed question and write `plan/.run-speed`.

An initiative step skips the run-mode question and the human confirmation, as I-C Run in `ravintio-zero/standards/roadmap-standards.md` describes.

In a gated run, state the context size before you ask for confirmation. See Context size at gates in Phase Invocation.

**Do not proceed to plan until the human has confirmed the design.** This is the hard gate. Present it, revise on request, and once confirmed, commit `design.md` and `feature-brief.md`. The pipeline then begins.

