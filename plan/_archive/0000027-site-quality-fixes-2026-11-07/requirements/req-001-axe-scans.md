---
title: "Requirement: REQ-001 - Add axe-core accessibility scans"
summary: "The Playwright suite scans every page in both themes and fails on serious or critical violations."
status: "active"
version: "0.1.0"
---
# Requirement: REQ-001 - Add axe-core accessibility scans

**Skill:** [plan](../skills/ravintio-plan/SKILL.md)
**Feature:** 0000027-site-quality-fixes
**Source:** US-001
**Priority:** should-have

## User Story

As a maintainer, I run an axe-core scan on every page in both themes, so that CI catches accessibility rules a manual review misses.

## Functional Requirements
- `@axe-core/playwright` joins `devDependencies` at an exact version.
- A Playwright spec scans the homepage, the sitemap, `/404.html`, and every manifest page with the tags `wcag2a`, `wcag2aa`, `wcag21a`, `wcag21aa`, and `wcag22aa`.
- The spec scans each page twice, once per theme, with the theme set before load.
- The spec waits for Mermaid diagrams to render before it scans.
- The spec writes moderate and minor violations to `test-results/axe-report.json`.
- The run fixes every serious or critical violation the first scan finds. A rule exclusion needs human approval.

## Acceptance Criteria
- [ ] AC-1: Every page in both themes
  - Given the built site on the preview server
  - When the Playwright suite runs
  - Then it scans each page path in light and in dark with the WCAG 2.2 AA tags
- [ ] AC-2: Serious and critical fail
  - Given a page with a serious or critical violation
  - When the suite scans it
  - Then the test for that page and theme fails and names the rule
- [ ] AC-3: Report for triage
  - Given a scan that finds moderate or minor violations
  - When the suite finishes
  - Then `test-results/axe-report.json` lists each one with its page, theme, rule, and impact

## Dependencies
- REQ-002 and REQ-003, whose page and markup this scan covers.
