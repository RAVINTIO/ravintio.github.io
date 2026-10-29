---
title: "Requirement: REQ-002 - zero-adoption-guide"
summary: "Detailed requirements for this specific functional feature."
status: "active"
version: "0.1.0"
---
# Requirement: REQ-002 - zero-adoption-guide

**Skill:** [plan](../skills/ravintio-plan/SKILL.md)
**Feature:** 0000005-ravintio-docs-rewrite
**Source:** US-002
**Priority:** must-have

## User Story

As a developer adopting Zero, I follow the install and first-run guides, so that I can take a first feature to a pull request using only the site.

## Functional Requirements
- Page 3, "Zero overview", explains what Zero does, why, and its limits, from the Zero README and the pack.
- Page 4, "Install Zero", covers prerequisites, installing into a new repo, and installing into an existing repo, with the exact commands from `ravintio-zero/setup.sh`.
- Page 5, "Your first run", walks a reader from a feature brief through P0 to P4 to a pull request.
- Page 6, "The pipeline", covers the five phases, prefixes, gates, run modes, run speed, pause, and park.
- Page 7, "Project operations", covers hooks, commit rules, overrides in `ravintio-overrides/`, and updating the pack.
- Every claim about Zero matches a file in `ravintio-zero/`. No content comes from the deleted pages.
- Every sentence on every site page stays under 25 words and avoids the style-guide blocklist.

## Acceptance Criteria
- [ ] AC-1: Zero pages present in order
  - Given the site is built
  - When a reader opens the Zero nav section
  - Then it lists pages 3 to 7 in the confirmed order
- [ ] AC-2: Every internal link resolves
  - Given the built site
  - When the link test follows every internal link and anchor on every page
  - Then each target file and anchor exists
- [ ] AC-3: Prose meets the style rules
  - Given every page in `src/site-content/pages/`
  - When the style test splits prose into sentences, skipping code, tables, and headings
  - Then no sentence reaches 25 words
  - And no page uses a blocklisted word

## Dependencies
- REQ-004 for the nav sections and the `site-content` component.
- REQ-003 for links into the reference pages.
