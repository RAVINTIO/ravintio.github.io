---
title: "Requirement: REQ-001 - Rebalance the explainer to all six tools"
summary: "The explainer and homepage subtitle present all six tools and their shared purpose."
status: "active"
version: "0.1.0"
---
# Requirement: REQ-001 - Rebalance the explainer to all six tools

**Skill:** [plan](../skills/ravintio-plan/SKILL.md)
**Feature:** 0000024-explainer-six-tools
**Source:** US-001
**Priority:** must-have

## User Story

As a new reader, I read one page that explains all six tools and their shared purpose, so that I see RAVINTIO as more than a coding agent.

## Functional Requirements
- The opening paragraph of `what-is-ravintio.md` names visibility and governance over agentic software development.
- The first H2 is "Why RAVINTIO?". It explains the shared purpose and names no single tool.
- An H2 "The six tools" follows, with one H3 entry per tool in the order Zero, Framework, Accept, Qualify, Insight, Unbound.
- The longest tool entry has at most 1.5 times the words of the shortest.
- Entries for in-design tools state aims in active voice and never claim a feature exists.
- The three areas, shared principles, and independence sections stay. The "Where to go next" section links to the tool overview first.
- The homepage subtitle names the shared purpose and no single tool.
- Links to `what-is-ravintio.md#why-use-ravintio` move to the new anchor `#why-ravintio`.

## Acceptance Criteria
- [ ] AC-1: Purpose first, and the why names no tool
  - Given the built `what-is-ravintio` page
  - When a test reads the opening paragraph and the first H2 section
  - Then the opening paragraph names visibility and governance over agentic software development
  - And the first H2 is "Why RAVINTIO?" and its text names none of the six tools
- [ ] AC-2: Balanced tool entries
  - Given the "The six tools" section of `what-is-ravintio.md`
  - When a test counts the words in each H3 entry
  - Then there are six entries, one per tool
  - And the longest entry has at most 1.5 times the words of the shortest
- [ ] AC-3: Purpose-led subtitle
  - Given the built homepage
  - When a test reads the hero subtitle
  - Then it names visibility and governance over agentic software development
  - And it names none of the six tools

## Dependencies
- Updates `why-use-ravintio.test.mjs`, `copy-fixes.test.mjs`, and `zero-overview.test.mjs`, which pin the current text.
