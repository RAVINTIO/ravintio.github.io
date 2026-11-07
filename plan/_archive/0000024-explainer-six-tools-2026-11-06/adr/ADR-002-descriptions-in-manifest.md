---
title: "ADR 002: Page descriptions live in the docs manifest"
summary: "web-app owns each page's meta description through a description field in docs.manifest.json."
status: "accepted"
version: "0.1.0"
---
# ADR-002 - Page descriptions live in the docs manifest

**Skill:** [plan](../skills/ravintio-plan/SKILL.md)
**Feature:** 0000024-explainer-six-tools
**Component:** web-app
**Date:** 2026-11-06

## Context

REQ-002 adds a meta description to each doc page. `site-content` owns the page Markdown (0000005 ADR-002). `web-app` owns `docs.manifest.json`, which already holds each page title (0000005 ADR-003). The description needs one owner.

## Decision

Add a `description` field to each page entry in `docs.manifest.json`. `web-app` owns it. `build-docs.js` writes it into `<head>` and fails the build if it is missing.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Front matter in each page | The summary sits beside its page, owned by `site-content` | `build-docs.js` has no front matter parser, and the title already lives in the manifest | Splits page metadata across two owners |
| Derive from the first paragraph | No new field | Long or off-topic text, and no length control | Fails the 50 to 160 character rule |

## Affected Components

| Component | Impact |
|-----------|--------|
| web-app | Owns the field and writes it into each page |
| site-content | None. A page author also updates the manifest when a page's purpose changes. |

## Consequences

**Positive:**
- All page metadata sits in one file with one owner.

**Negative:**
- A page change can leave its description stale, because the two live in different components.

**Risks:**
- A new page without a description fails the build, which is the intended guard.

## Related ADRs

- 0000005 ADR-002 site-content owns pages - related-to
- 0000005 ADR-003 sectioned nav manifest - extends
