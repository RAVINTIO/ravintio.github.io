---
title: "Requirement: REQ-004 - playwright-mcp-config"
summary: "Detailed requirements for this specific functional feature."
status: "active"
version: "0.1.0"
---
# Requirement: REQ-004 - playwright-mcp-config

**Skill:** [plan](../skills/ravintio-plan/SKILL.md)
**Feature:** 0000016-site-regression-and-quality
**Source:** US-004
**Priority:** must-have

## User Story

As a contributor, I get Playwright MCP from the repo's own config, so that every session in this repo has the same browser tools.

## Functional Requirements
- `.mcp.json` at the repo root declares one server named `playwright`.
- The server runs `npx` with `@playwright/mcp@0.0.83`, an exact version.
- A `node --test` test parses `.mcp.json` and checks the server name, command, and exact version.

## Acceptance Criteria
- [ ] AC-1: The repo declares a pinned Playwright MCP
  - Given the repo root
  - When a test parses `.mcp.json`
  - Then it holds a `playwright` server that runs `@playwright/mcp` at exactly `0.0.83`
  - And no version range or `latest` tag appears

## Dependencies
- None.
