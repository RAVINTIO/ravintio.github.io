# Orchestrator reference: phase invocation

> Read this file before you invoke P1, P2, P3, or P4. The orchestrator `SKILL.md` points here from its Pack Index.

## Phase Invocation (P1 to P4)

Conventions for every downstream phase:

- **Build log first:** append a `### P<n>: {Phase Name}` block before any phase work (Hard Limit 9).
- **Load the phase skill before acting.** Read it in full first.
- **Commit** all new artifacts before presenting the gate summary.
- **Push cadence:** after each gate commit, if remote push is authorised by a standing override in `ravintio-overrides/instructions/` or a per-session grant in the build log, push the feature branch. A failed push is an exception stop (see Exception Stops).
- **Skills inbox:** re-check at each transition.
- **Run mode:** read `plan/.run-mode` at each transition and apply that phase's STOP rule below.
- **Run speed:** read `plan/.run-speed`. At `fast`, dispatch the phase's fast batch.
- **Close the block:** when a phase completes, fill `End` and `Wall clock`.

| Phase | Invoke | Gate condition | STOP rule |
|-------|--------|----------------|-----------|
| P1 Plan | ravintio-plan | Artifact set complete (requirements, ADRs, OpenAPI where applicable) | Gated: STOP for confirmation. Autonomous: no stop. |
| P2 Implement | ravintio-implement | Implementation matches the spec, and docs land with code | Gated: STOP for confirmation. Autonomous: no stop. |
| P3 Validate and Accept | ravintio-validate-and-accept | CI green plus acceptance evidence | Gated: STOP for acceptance. Autonomous: no stop. The evidence goes in the PR description. |
| P4 Ship | ravintio-ship | Archive, build report, changelog, tag, and PR (or PR description) | Gated: STOP before the PR. Autonomous: no stop. Raise the PR, then end the run. |

**Context size at gates.** At each phase gate in a gated run, state the approximate context size before you ask for approval. The P0 design gate counts, and so do the P1, P2, and P3 gates and the P4 ship gate.

- Use the usage figure the host reports, such as the context meter in Claude Code.
- If the host reports none, give a stated estimate, labelled as an estimate.
- If the size passes about 150,000 tokens, recommend `/clear` or a new session before the next phase. The `plan/current/` artifacts carry the state, so a clear loses none. Tell the human to start the new session and let Resume Detection continue from the build log.
- The statement is advisory. It never blocks, delays, or skips a gate.
- An autonomous run or an initiative step does not report context size. Each initiative step already starts a fresh session.

**Before P2:** check the declared stack against installed capability skills and recommend loading relevant ones. Then apply subagent decomposition for every requirement: consult `## Skill Map` in `design.md` for the best-fit skill, select the model tier, and dispatch per the dispatch standards below.

**After P4:** apply the Context Hygiene reset so the next session starts cold.

**Merge is human-only.** Merging into `main` stays human-only in every run mode, and the agent never commits to `main`. The one exception is `gh pr merge --squash` for the agent's own feature PR into `initiative/*`, after a clean P3 and green CI. The `merge-guard` hook enforces it. See `ravintio-zero/standards/roadmap-standards.md`.

