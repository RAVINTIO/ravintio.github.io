---
title: "Requirement: REQ-001 - ravintio-overview"
summary: "Detailed requirements for this specific functional feature."
status: "active"
version: "0.1.0"
---
# Requirement: REQ-001 - ravintio-overview

**Skill:** [plan](../skills/ravintio-plan/SKILL.md)
**Feature:** 0000005-ravintio-docs-rewrite
**Source:** US-001
**Priority:** must-have

## User Story

As a developer evaluating agent tooling, I read what RAVINTIO is and what each of its six tools does, so that I can pick the tool that fits my problem.

## Functional Requirements
- Page 1, "What is RAVINTIO", explains the name as an abbreviation of eight qualities and lists the eight principles with their meaning.
- Page 1 describes the three areas (autonomous engineering, verification and assessment, experimental research) and the shared design principles.
- Page 2, "The six tools", gives each tool its purpose, what it owns, what it does not own, and its status label.
- Status labels: Zero and Framework "Available". Accept, Qualify, and Insight "In design". Unbound "In design, experimental research only".
- Page 2 states that the tools work independently and describes how they can relate.
- Neither page holds the strategy's private sections: implementation sequence, open design questions, threat model, or proposed repo names.
- Neither page gives a release date, a sequence, or "coming soon" wording.

## Acceptance Criteria
- [ ] AC-1: Overview pages present
  - Given the site is built
  - When a reader opens the RAVINTIO nav section
  - Then it lists "What is RAVINTIO" and "The six tools" in that order
  - And page 1 names all eight principles
- [ ] AC-2: Every tool carries its status label
  - Given page 2 is built
  - When the test reads each tool's section
  - Then each of the six tools shows exactly its confirmed status label
- [ ] AC-3: No private strategy content
  - Given pages 1 and 2
  - When the human reviews them against the criterion 4 checklist
  - Then no page holds an implementation sequence, open design question, threat model, proposed repo name, date, or "coming soon" wording

## Dependencies
- REQ-004 for the nav sections and the `site-content` component.
