---
title: "Requirement: REQ-003 - Remove passive sentences from doc pages"
summary: "Doc pages use active voice, and a style test keeps it that way."
status: "active"
version: "0.1.0"
---
# Requirement: REQ-003 - Remove passive sentences from doc pages

**Skill:** [plan](../skills/ravintio-plan/SKILL.md)
**Feature:** 0000024-explainer-six-tools
**Source:** US-003
**Priority:** must-have

## User Story

As a reader, I read sentences that name who acts, so that I know what each tool does.

## Functional Requirements
- The nine sentences that backlog 0000021 lists use active voice with a named actor.
- `style.test.mjs` flags "is", "are", "was", or "were", with an optional adverb, before a participle in page prose.
- An allowlist in the test holds adjective uses such as "are merged", each with a comment.
- Every page passes the new check. "Is designed to" and "is meant to" hedges become active wording such as "aims to".

## Acceptance Criteria
- [ ] AC-1: Listed sentences fixed
  - Given the nine sentences from backlog 0000021
  - When a test searches the three pages for their passive phrases
  - Then none of the phrases remain
- [ ] AC-2: Voice check on every page
  - Given the passive-voice check in `style.test.mjs`
  - When it runs over every page
  - Then it reports no hits outside the allowlist
  - And it flags a sample passive sentence fed to it directly

## Dependencies
- Runs after REQ-001, which rewrites `what-is-ravintio.md`.
