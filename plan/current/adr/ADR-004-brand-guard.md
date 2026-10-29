---
title: "ADR 004: Guard against the earlier brand with an allowlisted test"
summary: "A test fails the build when the earlier brand appears in any tracked file name or content outside an allowlist of history paths."
status: "accepted"
version: "0.1.0"
---
# ADR-004 - Guard against the earlier brand with an allowlisted test

**Skill:** [plan](../skills/ravintio-plan/SKILL.md)
**Feature:** 0000005-ravintio-docs-rewrite
**Component:** web-app
**Date:** 2026-10-29

## Context

The human ruled that no published page names the earlier brand. The backlog entry pulled in for this run asks for a brand guard with a path allowlist. History paths must keep the old name.

## Decision

Add `src/web-app/tests/brand-guard.test.mjs`. It lists tracked files with `git ls-files` and also walks `dist/`. It fails on any case-insensitive match of the earlier brand in a path or in file content. The allowlist holds `plan/_archive/`, `plan/changelog/`, `ravintio-zero/`, and the guard test file. The test builds the search term from two string parts, so its own source holds no match.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| A pre-commit hook | Catches the brand before commit | The pack owns the hooks, and hooks can be skipped | A test runs in CI and can't be skipped there |
| A one-off grep at P3 | No code to maintain | Nothing stops the brand returning later | The guard must hold after this run |

## Affected Components

| Component | Impact |
|-----------|--------|
| web-app | Gains the guard test |

## Consequences

**Positive:**
- The brand can't return without a failing test.

**Negative:**
- Any future file that must name the earlier brand needs an allowlist edit.

**Risks:**
- The installed pack mentions the brand in its own history. Mitigation: the allowlist covers `ravintio-zero/`, which this repo doesn't edit.

## Related ADRs

- ADR-001 - depends-on

## Supersedes

- none

## Superseded By

- none
