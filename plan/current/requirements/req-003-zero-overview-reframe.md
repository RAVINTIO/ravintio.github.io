---
title: "Requirement: REQ-003 - zero-overview-reframe"
summary: "Detailed requirements for this specific functional feature."
status: "active"
version: "0.1.0"
---
# Requirement: REQ-003 - zero-overview-reframe

**Skill:** [plan](../skills/ravintio-plan/SKILL.md)
**Feature:** 0000009-bug-fixes
**Source:** US-003
**Priority:** must-have

## User Story

As a developer evaluating Zero, I read why to use Zero and when it fits before its glossary, so that the page helps me decide.

## Functional Requirements
- The first H2 in `zero-overview.md` is "Why use Zero", followed by "How a run flows". "Terms" is the last H2.
- "Why use Zero" replaces "Why Zero exists". It lists Zero-specific reasons in benefit form, led by the confirmed design and plan you review before code exists. It links to "Why use RAVINTIO" on `what-is-ravintio.md` and doesn't repeat that list. It drops the risk-essay framing.
- "When Zero fits" replaces "Limits of Zero" and states fit positively. Zero suits changes you will maintain. A throwaway prototype may not need it.
- The page has no "No benchmarks exist" line and no "Overhead is real" phrasing.
- Every claim matches the installed `ravintio-zero/` pack.

## Acceptance Criteria
- [ ] AC-1: Section order
  - Given the built `zero-overview` page
  - When the content test lists its H2 headings
  - Then the first is "Why use Zero", the second is "How a run flows", and the last is "Terms"
- [ ] AC-2: When Zero fits
  - Given the built `zero-overview` page
  - When the content test reads its headings and text
  - Then "When Zero fits" exists and "Limits of Zero" doesn't
  - And the page holds no benchmark line

## Dependencies
- None.
