---
title: "ADR 005: Verify reference pages against the installed pack"
summary: "A test compares the skills, standards, and templates pages with the ravintio-zero folders and fails on any missing or extra item."
status: "accepted"
version: "0.1.0"
---
# ADR-005 - Verify reference pages against the installed pack

**Skill:** [plan](../skills/ravintio-plan/SKILL.md)
**Feature:** 0000005-ravintio-docs-rewrite
**Component:** site-content
**Date:** 2026-10-29

## Context

The reference pages list items from the installed pack. The pack changes on each update. The Scope Lock error path says drift must fail the build. The reference pages are hand-written, so their wording stays readable.

## Decision

Add `src/web-app/tests/reference-match.test.mjs`. For each of `skills/` (folders), `standards/` (top-level `.md` files), and `templates/` (files), it reads the pack folder. It then reads every code-font name in a `###` heading or first table column on the matching page. The test fails if a pack item is absent from the page, or a page item is absent from the pack.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Generate the reference pages from the pack | No drift by construction | Wording comes from pack descriptions, which aren't written for site readers | The site's prose rules need hand-written text |
| No check | Less code | Silent drift, against the Scope Lock error path | Rejected by the confirmed error path |

## Affected Components

| Component | Impact |
|-----------|--------|
| site-content | Reference pages follow a fixed item format |
| web-app | Gains the test |

## Consequences

**Positive:**
- A pack update that adds or removes an item fails the build until the page is updated.

**Negative:**
- Every pack update needs a page edit, even for an internal file.

**Risks:**
- Supporting files such as guides match the template filter. Mitigation: the reference page lists every file in `templates/`, including guides.

## Related ADRs

- ADR-001 - depends-on

## Supersedes

- none

## Superseded By

- none
