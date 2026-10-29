# Your first run

This page walks you through one feature, from brief to pull request. The example adds a health-check endpoint to a small service called `acme-api`. The names are fictional. Your agent's wording will differ, but the prefixes and the order stay the same.

Before you start, complete [Install Zero](install-zero.md).

## 1. Check your setup

Make sure you committed the setup to `main`, as [Install Zero](install-zero.md) describes. If you had a Claude Code session open during setup, restart it. Claude Code reads hooks at session start.

You don't create the feature branch yourself. At the start of discovery, the agent reports your current branch and asks whether earlier pull requests are merged. It then offers `git checkout main` and `git checkout -b feat/{feature-id}`. It uses `feat/pending` until you confirm the id.

## 2. Write the feature brief

Copy the template and fill it in.

```bash
cp ravintio-zero/templates/feature-brief.template.md plan/current/feature-brief.md
```

A good brief states the problem, the target user, the stack, and the limits. For the example, the brief says that operators need a way to check whether the service is alive. It names the stack and asks for a `GET /health` endpoint that returns the service status. It lists what is out of scope, such as dependency checks.

The feature brief guide in [templates](templates.md) describes each section. Gaps are fine, because the agent asks about them.

## 3. Start the agent

Open your agent in the repository. On Claude Code, the auto-trigger hook loads the orchestrator skill at the start of the session. Codex has no such hook, so it relies on the instruction in `AGENTS.md`. Then send this prompt.

```text
Run the RAVINTIO pipeline.
Feature brief: plan/current/feature-brief.md
```

The agent opens with a status line.

```text
P0 Discovery: Starting: assessing the feature brief for the health-check endpoint
```

Before it asks questions, the agent does its start-of-run checks.

- It reports the current branch and asks whether earlier pull requests are merged.
- It looks for a `product.yml` with a product `id`. Every project needs one, even with a single component. If the file or the id is missing, the agent stops and asks you for a stable kebab-case id, such as `acme-api`.
- It scans the repository to detect the adoption mode and the last known version.
- It scans `plan/backlog/` for deferred items and offers each one to you.

## 4. Answer the discovery questions

The agent asks one question at a time and waits for your answer. Expect questions like this one.

```text
P0 Discovery: The brief doesn't say whether /health needs authentication.
I recommend no authentication because a load balancer calls it.
Confirm? (no authentication / require a token)
```

The agent recommends an answer and asks you to confirm or change it. Answer in plain language. If a recommendation is wrong, say so and the agent revises it. If you want to defer a topic, say that, and the agent records the deferral in the scope.

Near the end, the agent runs the Scope Lock Challenge. It drafts answers for four paths and shows them together, labelled as drafts.

- The happy path, from the first call to a healthy response.
- The first-run path, before any data exists.
- The error path, such as the service failing to start.
- Cross-session continuity, meaning what is at risk if the session stops.

You accept, edit, or reject each item. A blanket "looks fine" does not count. See [the Scope Lock Challenge](pipeline.md#the-scope-lock-challenge).

## 5. Confirm the design

The agent writes `plan/current/design.md` and presents it. The design names the components, the data owners, the scope, the risks, the version, and the approved dependencies. Read it carefully, because the agent can't change it without your approval.

Next, the agent asks two questions.

```text
How should the agent run P1 to P4?

  [1] Gated: the agent stops for you at the end of each phase
  [2] Autonomous: the agent runs to a raised PR and stops only for escalations

How fast should the agent run P1 to P4?

  [1] Standard: each phase decides its own batches
  [2] Fast: each phase dispatches its listed fast batch in one message
```

For a first run, choose gated and standard. Gated shows you each artefact before the next phase starts. The agent saves your answers in `plan/.run-mode` and `plan/.run-speed`.

Once you confirm, the agent commits `design.md` and `feature-brief.md`.

```text
P0 Discovery: Complete: design confirmed for 0000001-health-check, run mode gated
```

## 6. Review the plan in P1

```text
P1 Plan: Starting: producing requirements, scope, risks, glossary, and decision records
```

The agent writes the artefacts into `plan/current/`. It runs a consistency check and fixes what the check flags. Then it stops at the plan gate.

```text
P1 Plan: Complete: 3 requirements, 1 decision record, consistency check clean
```

Read the requirements and the scope. If something is wrong, tell the agent what to change. When you are satisfied, tell the agent to continue.

## 7. Watch the build in P2

```text
P2 Implement: Starting: building the health-check component with tests and docs
```

For each requirement, the agent writes one failing test, writes the minimum code to pass it, and then refactors. Documentation lands in the same phase. The agent commits as it goes and stops at the implement gate.

```text
P2 Implement: Complete: 3 of 3 requirements built, tests passing
```

If the agent needs a library that is not on the approved list, it stops and asks.

```text
P2 Implement: Blocked: new dependency express-health is not on the approved list. Approve it or choose an approved alternative.
```

## 8. Accept the result in P3

```text
P3 Validate: Starting: running CI checks and the security review
```

The agent runs the library audit, the semantic check, lint, typecheck, tests, and build. It also runs the code and records what it observed. If a check fails, the agent fixes the cause and re-runs, up to five times. Then it presents the evidence.

```text
P3 Validate: Complete: all checks pass, no critical or high security findings
```

You accept, request changes, or reject.

## 9. Ship in P4

```text
P4 Ship: Starting: changelog, archive, build assessment, and pull request
```

The agent writes the changelog, archives `plan/current/` to `plan/_archive/`, and writes a build report. In a gated run, it asks whether to push and raise the pull request or to print a description for you to use. If you choose to raise it, it finishes like this.

```text
P4 Ship: Complete: 0000001-health-check shipped.
```

You merge the pull request. The agent never merges into `main`. After the merge, CI tags the merge commit with the version.

## What you have now

- A pull request with code, tests, and documentation.
- An archived plan, a changelog entry, and a build report.
- A record of every decision, in git history.

Read [the pipeline](pipeline.md) for the detail behind each step. If you want to pause or shelve a run, see [pause, park, and resume](pipeline.md#pause-park-and-resume).
