---
title: "Requirement: REQ-002 - simplicity-guidance"
summary: "Detailed requirements for this specific functional feature."
status: "active"
version: "0.1.0"
---
# Requirement: REQ-002 - simplicity-guidance

**Skill:** [plan](../skills/ravintio-plan/SKILL.md)
**Feature:** 0000009-bug-fixes
**Source:** US-002
**Priority:** must-have

## User Story

As a developer, I read how Zero keeps solutions simple and avoids needless complexity, so that I trust it won't leave me a maintenance burden.

## Functional Requirements
- `what-is-ravintio.md` "Why use RAVINTIO" holds the agreed "Solutions stay as simple as the problem allows" bullet directly after "Constraints hold". REQ-001 writes it as part of the agreed list.
- `zero-overview.md` has a section "How Zero keeps solutions simple" with the agreed text, verbatim. It covers discovery, plan, implement, and standards.
- `pipeline.md` P2 section adds "Each cycle asks whether a simpler solution meets the same tests." directly after the sentence about the improvement loop.
- Every claim in the new text matches the installed `ravintio-zero/` pack.

## Acceptance Criteria
- [ ] AC-1: Zero overview simplicity section
  - Given the built `zero-overview` page
  - When the content test reads its sections
  - Then a section "How Zero keeps solutions simple" exists
  - And it holds the bullets for Discovery, Plan, Implement, and Standards
- [ ] AC-2: Pipeline P2 simplicity sentence
  - Given the built `pipeline` page
  - When the content test reads the P2 section
  - Then it holds "Each cycle asks whether a simpler solution meets the same tests."

## Dependencies
- REQ-001 writes the `what-is-ravintio.md` bullet.
- REQ-003 restructures `zero-overview.md`, so this requirement adds its section after that restructure.
