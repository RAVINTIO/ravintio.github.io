# Agreed copy - 0000009-bug-fixes

The human confirmed this text in P0. Use it verbatim where the text is given. Where only a direction is given, write new copy to that direction and the style guide.

## US-001: `what-is-ravintio.md`

Replace the H1 intro paragraph and the whole "The name" section (heading, intro, letter table, and the block-capitals sentence) with:

> # What is RAVINTIO
>
> RAVINTIO lets a coding agent do real engineering work on its own while you keep control of what ships. It's a set of open-source tools. RAVINTIO Zero and RAVINTIO Framework are available now.
>
> ## Why use RAVINTIO
>
> Coding agents write code fast. RAVINTIO makes that code something you can trust, review, and maintain.
>
> - **Changes are designed before they're built.** The agent works from a design and requirements you confirm. It builds against them and no further.
> - **Work follows your standards.** Code, tests, commits, and docs follow the same standards on every change. Hooks block commits and actions that break your rules.
> - **Documentation comes with the code.** Every component gets the same set of docs: purpose, interface, dependencies, risks, and test coverage. Project-wide docs stay current with each change.
> - **Architectural decisions are on record.** Each significant choice gets a decision record. The record states the context, the options, and the consequences, good and bad.
> - **Constraints hold.** The agent uses only the dependencies you approved, and it stays inside the boundaries you set. Outside them, it stops and asks you.
> - **Solutions stay as simple as the problem allows.** The agent builds what the requirements ask for and no more. It writes the minimum code to pass each test, then looks for a simpler version. Unneeded layers, unused code, and speculative features never reach your codebase. They would become someone's maintenance burden later.
> - **Done means proven.** The agent runs the tests, the checks, and the software itself before it hands back. The pull request carries the evidence.
> - **Failures get fixed, not reported.** The agent diagnoses build, test, and security failures and repairs them before it escalates.
> - **Work survives a new session.** Plans, decisions, and progress live in plain files in your repo. Work resumes where it stopped.
> - **No lock-in.** RAVINTIO works with your own CI, version control, and pull request flow. It adds no service to run.

Keep "The three areas", "The tools work independently", and "Where to go next".

Trim "Shared design principles" to these three bullets, keeping their current wording:

- Humans keep authority over consequential decisions.
- Assessment challenges the work.
- Learning is blameless.

Also update `six-tools.md` line 3: "For the name and shared principles" no longer fits. Point to the page for why to use RAVINTIO and its principles.

## US-002: simplicity guidance

The `what-is-ravintio.md` bullet is in the list above.

New section in `zero-overview.md`, "How Zero keeps solutions simple":

> Complexity that nobody asked for becomes a cost you pay on every later change. Zero works against it at each stage.
>
> - **Discovery** sizes each release. If the work is too large for one run, the agent recommends a split.
> - **Plan** derives requirements from your stories only. The agent never invents a requirement. Each decision record must state the downsides of a choice as well as the gains.
> - **Implement** writes the minimum code to pass each test. An improvement loop then asks whether a simpler solution passes the same tests.
> - **Standards** favour clarity over cleverness and code you can delete without side effects. They name over-abstraction and unused code as faults to remove.

`pipeline.md`, P2 section: after the sentence about the improvement loop, add "Each cycle asks whether a simpler solution meets the same tests."

## US-003: `zero-overview.md` reframe (direction)

- Order: lead with "Why use Zero", then "How a run flows". Move "Terms" to the end of the page.
- "Why Zero exists" becomes "Why use Zero": Zero-specific reasons in benefit form, led by the confirmed design and plan you review before code exists. Link back to "Why use RAVINTIO" rather than repeating it. Drop the risk-essay framing.
- "Limits of Zero" becomes "When Zero fits", stated positively. Zero suits changes you will maintain. A throwaway prototype may not need it. Drop "No benchmarks exist" and "Overhead is real" phrasing.

## US-004: copy fixes

1. `first-run.md` step 2: add `mkdir -p plan/current` before the `cp` command. Setup creates `plan/` but not `plan/current/`.
5. `install-zero.md` prerequisites: delete "The pack states no minimum version."
6. `first-run.md` "What you have now" (direction): add what the outputs give you. A reviewer sees the design, the decisions, and the evidence in one PR. The next session or person picks up the reasoning from the repo.
7. `six-tools.md`: rename every "What it owns" to "What it does" and every "What it doesn't replace" to "What it works alongside".
8. `src/web-app/index.html` hero subtitle: "Coding agents that build to your design and standards, and prove the result."
