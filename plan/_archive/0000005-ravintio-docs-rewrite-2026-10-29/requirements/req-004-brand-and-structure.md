---
title: "Requirement: REQ-004 - brand-and-structure"
summary: "Detailed requirements for this specific functional feature."
status: "active"
version: "0.1.0"
---
# Requirement: REQ-004 - brand-and-structure

**Skill:** [plan](../skills/ravintio-plan/SKILL.md)
**Feature:** 0000005-ravintio-docs-rewrite
**Source:** US-004
**Priority:** must-have

## User Story

As a reader, I find the site under the RAVINTIO name and logo with no trace of the earlier brand, so that the product reads as one thing.

## Functional Requirements
- A new `site-content` component at `src/site-content/` owns the pages in `pages/` and its docs in `docs/`.
- `planifest-docs/` and `src/planifest-docs/` are deleted, with all old pages.
- `docs.manifest.json` groups pages into three labelled sections: RAVINTIO, Zero, and Reference. `build-docs.js` reads pages from `src/site-content/pages/` and renders the grouped nav.
- The header shows the supplied logo beside a "RAVINTIO" wordmark. The favicon set comes from the same logo. Old logo and favicon files are deleted.
- The homepage, page titles, metadata, and repo links name RAVINTIO and point at `github.com/RAVINTIO/ravintio-zero`.
- Repo docs (`README.md`, `docs/`, `plan/README.md`, `plan/feature-structure.md`) and the PowerShell refresh helper carry no earlier-brand text.
- The earlier brand name appears nowhere outside `plan/_archive/`, `plan/changelog/`, and git history.
- Every brand mention outside code identifiers and URLs reads `RAVINTIO` in block capitals.

## Acceptance Criteria
- [ ] AC-1: Build passes with grouped nav
  - Given the repo at the feature branch
  - When `npm run build` runs in `src/web-app`
  - Then it exits 0
  - And every built page shows three labelled nav sections holding the ten pages in the confirmed order
- [ ] AC-2: No earlier-brand text
  - Given every tracked file and every file in `dist/`
  - When the brand guard test searches names and contents case-insensitively for the earlier brand
  - Then it finds no match outside the allowlisted paths
- [ ] AC-3: Brand in block capitals
  - Given the pages, the homepage, and the built site
  - When the capitals test searches for the brand in any other case
  - Then it finds no match outside code spans, code blocks, URLs, and file paths

## Dependencies
- None. REQ-001, REQ-002, and REQ-003 depend on this requirement.
