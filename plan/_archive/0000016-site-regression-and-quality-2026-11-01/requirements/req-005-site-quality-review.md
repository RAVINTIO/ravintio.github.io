---
title: "Requirement: REQ-005 - site-quality-review"
summary: "Detailed requirements for this specific functional feature."
status: "active"
version: "0.1.0"
---
# Requirement: REQ-005 - site-quality-review

**Skill:** [plan](../skills/ravintio-plan/SKILL.md)
**Feature:** 0000016-site-regression-and-quality
**Source:** US-005
**Priority:** must-have

## User Story

As the maintainer, I get a site quality review in P3 of every run, so that urgent defects get fixed and other improvements reach the backlog.

## Functional Requirements
- `ravintio-overrides/capability-skills/site-quality-review/SKILL.md` holds the review procedure.
- `ravintio-overrides/instructions/custom-003-site-quality-review.md` runs the skill in P3 of every run, after the Playwright suite passes.
- The skill builds the site and serves it with `vite preview`. It reviews the pages through Playwright MCP and opens only the local preview origin.
- The skill writes `plan/current/site-quality-report.md` from a report template in the skill folder. It writes each finding to disk as it goes.
- The report covers five areas, each with its target:
  - Accessibility: WCAG 2.2 AA, read from the accessibility tree.
  - Layout: 390 px and 1280 px, in both themes.
  - Content: the repo's writing style and the installed pack's facts.
  - Performance: page weight under 500 KB, and LCP under 2.5 s on the preview.
  - Navigation and metadata: a unique `<title>` and meta description, a working 404, and a favicon.
- A finding is fix-now when any of these is true:
  - The current run caused it.
  - It fails WCAG 2.2 level A.
  - A link or anchor is broken, or a page logs a console error.
  - A page breaks at 390 px, with overlap, clipping, or horizontal scroll.
- Every other finding becomes a `plan/backlog/` entry with the page, the area, the evidence, and a suggested fix.
- If fix-now work passes 2 points, the skill stops and asks the human which findings to fix.
- Before filing, the skill checks `plan/backlog/` for an entry on the same page and issue. If it finds one, it adds the new evidence there and files nothing new.
- If Playwright MCP is not available, the skill stops with a `Blocked:` line.
- `node --test` tests check the skill and the instruction for the areas, targets, rule, cap, duplicate check, and phase.

## Acceptance Criteria
- [ ] AC-1: Every run reviews the site in P3
  - Given repo instruction `custom-003-site-quality-review.md`
  - When a run reaches P3 and the Playwright suite passes
  - Then the run loads the `site-quality-review` skill and runs it
- [ ] AC-2: The report covers five areas with targets
  - Given a review run
  - When it finishes
  - Then `plan/current/site-quality-report.md` holds a section for each of the five areas, with its target and findings
- [ ] AC-3: Findings are sorted, capped, and not duplicated
  - Given review findings
  - When the skill sorts them
  - Then each finding is marked fix-now or backlog by the rule
  - And fix-now work over 2 points stops for the human
  - And a finding that matches a backlog entry adds evidence there instead of a new entry

## Dependencies
- REQ-001 and REQ-002, because the review runs after the suite passes.
- REQ-004 for Playwright MCP.
