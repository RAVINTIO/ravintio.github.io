---
title: "Requirement: REQ-001 - why-use-ravintio"
summary: "Detailed requirements for this specific functional feature."
status: "active"
version: "0.1.0"
---
# Requirement: REQ-001 - why-use-ravintio

**Skill:** [plan](../skills/ravintio-plan/SKILL.md)
**Feature:** 0000009-bug-fixes
**Source:** US-001
**Priority:** must-have

## User Story

As a developer evaluating agent tooling, I read why I should use RAVINTIO before any detail about the name or the tools, so that I can judge its value quickly.

## Functional Requirements
- `what-is-ravintio.md` opens with the agreed H1 intro paragraph from `plan/current/agreed-copy.md`, verbatim.
- The second section is "Why use RAVINTIO", with the agreed lead sentence pair and the ten agreed bullets in the agreed order, verbatim.
- The page has no "The name" heading, no letter table, and no sentence telling readers to write the brand in block capitals.
- "Shared design principles" holds three bullets, with their current wording: human authority, assessment that challenges the work, and blameless learning.
- "The three areas", "The tools work independently", and "Where to go next" stay.
- `six-tools.md` line 3 points readers to `what-is-ravintio.md` for why to use RAVINTIO and its principles, not for "the name".

## Acceptance Criteria
- [ ] AC-1: Why use RAVINTIO holds the agreed list
  - Given the built `what-is-ravintio` page
  - When the content test reads its sections
  - Then the first H2 is "Why use RAVINTIO" and it holds the ten agreed bullet leads in order
  - And the page has no "The name" heading, no letter table, and no block-capitals sentence
- [ ] AC-2: Principles trimmed
  - Given the built `what-is-ravintio` page
  - When the content test reads "Shared design principles"
  - Then the section holds exactly three bullets: human authority, assessment that challenges the work, and blameless learning

## Dependencies
- None. REQ-002 adds no text to this page beyond the agreed list, which already holds the simplicity bullet.
