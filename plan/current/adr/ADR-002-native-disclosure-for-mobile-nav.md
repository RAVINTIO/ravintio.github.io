---
title: "ADR 002: Use a native disclosure for the mobile page list"
summary: "The page list sits in a details and summary pair, closed by script below 900 px and shown as the sidebar above it."
status: "accepted"
version: "0.1.0"
---
# ADR-002 - Use a native disclosure for the mobile page list

**Skill:** [plan](../skills/ravintio-plan/SKILL.md)
**Feature:** 0000009-bug-fixes
**Component:** web-app
**Date:** 2026-10-31

## Context

Below 900 px the page list stacks above the content, so a phone reader scrolls past ten links before the first heading. The human chose a collapsed disclosure above the content, closed by default and naming the current page. The design sets WCAG 2.2 AA as the accessibility target. The site has no front-end framework and no component library.

## Decision

`build-docs.js` wraps the page list in `<details open>` with a `<summary>` that names the current page. Below 900 px, `main.ts` removes the `open` attribute on load. At 900 px and above, CSS hides the `<summary>`, and the open `<details>` shows the sidebar as before. Without JavaScript the list stays open.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Custom button with `aria-expanded` and script | Full control of the markup and animation | Hand-written keyboard and state handling to test and maintain | The native element gives keyboard use and state for free |
| Move the page list into the header menu | One menu for all navigation | Larger change to the header and every page | The human chose the disclosure in P0 |
| CSS-only closed state with `<details>` and no `open` attribute | No script | The list is closed without JavaScript too, and desktop needs it open | Breaks the no-JavaScript fallback and the desktop sidebar |

## Affected Components

| Component | Impact |
|-----------|--------|
| web-app | `build-docs.js` page template, `main.ts` load handler, and `style.css` sidebar rules change |

## Consequences

**Positive:**
- Keyboard use and the expanded state come from the browser, with no ARIA code to maintain.
- The desktop sidebar and the no-JavaScript view stay as they are.

**Negative:**
- The list renders open and then closes on a phone, so a slow script can show a brief flash.

**Risks:**
- A resize across 900 px leaves the list closed at desktop width. Mitigation: CSS forces the list visible at 900 px and above, whatever the `open` state.

## Related ADRs

- ADR-001 - related-to

## Supersedes

- none

## Superseded By

- none
