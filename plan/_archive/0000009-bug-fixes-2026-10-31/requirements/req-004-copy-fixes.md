---
title: "Requirement: REQ-004 - copy-fixes"
summary: "Detailed requirements for this specific functional feature."
status: "active"
version: "0.1.0"
---
# Requirement: REQ-004 - copy-fixes

**Skill:** [plan](../skills/ravintio-plan/SKILL.md)
**Feature:** 0000009-bug-fixes
**Source:** US-004
**Priority:** must-have

## User Story

As a developer adopting Zero, I follow the install and first-run pages without a failing command or confusing wording, so that my first run works.

## Functional Requirements
- `first-run.md` step 2 runs `mkdir -p plan/current` before the `cp` command.
- `install-zero.md` prerequisites drop "The pack states no minimum version."
- `first-run.md` "What you have now" says what the outputs give you. A reviewer sees the design, the decisions, and the evidence in one PR. The next session or person picks up the reasoning from the repo.
- `six-tools.md` renames every "What it owns" heading to "What it does" and every "What it doesn't replace" heading to "What it works alongside".
- The `src/web-app/index.html` hero subtitle reads "Coding agents that build to your design and standards, and prove the result."

## Acceptance Criteria
- [ ] AC-1: First-run step 2 succeeds on a fresh setup
  - Given a temporary folder holding only `ravintio-zero/` and a `plan/` folder with no `current/`
  - When the test runs the step 2 commands from `first-run.md`
  - Then every command exits 0 and `plan/current/feature-brief.md` exists
- [ ] AC-2: Review findings 5 to 8 applied
  - Given the built site
  - When the content test reads `install-zero`, `first-run`, `six-tools`, and the homepage
  - Then `install-zero` has no "no minimum version" sentence, and `first-run` "What you have now" names the reviewer and the next session
  - And `six-tools` has only "What it does" and "What it works alongside" headings of that kind, and the hero subtitle matches the agreed text

## Dependencies
- REQ-001 edits line 3 of `six-tools.md`, so this requirement edits that page after REQ-001.
