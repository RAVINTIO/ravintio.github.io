---
title: "ADR 004: Set the theme with an inline script before first paint"
summary: "An inline script at the top of head sets data-theme before any stylesheet, and a color-scheme meta tag sets the canvas. This removes the light first frame for dark-theme readers."
status: "accepted"
version: "0.1.0"
---
# ADR-004 - Set the theme with an inline script before first paint

**Skill:** [plan](../skills/ravintio-plan/SKILL.md)
**Feature:** 0000016-site-regression-and-quality
**Component:** web-app
**Date:** 2026-11-01

## Context

`main.ts` sets `data-theme` on `<html>`. Both templates load it as `<script type="module">`, which the browser defers until the document is parsed. `style.css` puts the light palette on `:root`. A reader on the dark theme therefore sees one light frame on each page load (backlog 0000013).

## Decision

Both `index.html` and the `build-docs.js` template hold a short inline script at the top of `<head>`, before any stylesheet. It reads `localStorage` key `ravintio-theme` and accepts only `light` or `dark`. With no valid value, it uses `prefers-color-scheme`. A `try` block covers a `localStorage` that throws. Both templates also hold `<meta name="color-scheme" content="light dark">`. `main.ts` keeps the toggle.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| A `prefers-color-scheme` media query for the default palette only | No script | Ignores a saved choice that differs from the system | Fails REQ-006 AC-1 and AC-2 for those readers |
| A blocking external script in `<head>` | No inline code | An extra request blocks first paint | Slower than a few inline lines |

## Affected Components

| Component | Impact |
|-----------|--------|
| web-app | Both page templates gain an inline script and a meta tag |

## Consequences

**Positive:**
- The first frame matches the reader's theme.

**Negative:**
- The theme logic exists in two places, the inline script and `main.ts`.

**Risks:**
- A future Content Security Policy that forbids inline scripts must allow this one by hash (R-007).

## Related ADRs
- ADR-001 - related-to: the suite tests this script.

## Supersedes
- none

## Superseded By
- none
