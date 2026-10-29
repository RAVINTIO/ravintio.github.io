# Decisions Index

> Living document. Index of all ADRs across all features. Updated after every pipeline run.
> Do not archive this file. Update it in place.

Last updated: 0000005-ravintio-docs-rewrite

---

## All Architecture Decision Records

| ADR | Title | Feature | Status | Summary |
|-----|-------|---------|--------|---------|
| ADR-001 | Static Site Generation with Vite | website (pre-ID) | active | Vite builds pure static HTML with no server runtime |
| ADR-002 | Build-Time Markdown Rendering | website (pre-ID) | active | `marked` compiles Markdown to HTML at build time |
| ADR-003 | Deployment via GitHub Actions to GitHub Pages | website (pre-ID) | active | GitHub Actions builds on merge to `main` and publishes `dist/` |
| ADR-001 | Manifest as Page-Order Source of Truth | 0000001-doc-nav | amended | The manifest still sets page order. 0000005 ADR-003 changed its format to sections. |
| ADR-002 | Nav Injection via Template Placeholder | 0000001-doc-nav | superseded | The build now renders the nav in its page template (0000005 ADR-003) |
| ADR-001 | Three-File Docs Structure | 0000002-doc-structure | superseded | Replaced by the ten-page, three-section structure of 0000005 |
| ADR-002 | Two-Tier Depth Model | 0000002-doc-structure | superseded | Replaced by the ten-page, three-section structure of 0000005 |
| ADR-003 | Project Operations as a Dedicated Website Page | 0000002-doc-structure | superseded | Page placement now comes from 0000005 ADR-003 |
| ADR-001 | Content Folder Formalised as a Tracked Component | 0000003-p9-phase-docs | superseded | Replaced by `site-content` (0000005 ADR-002) |
| ADR-002 | Remove Broken Anchors, Not Add Sections | 0000003-p9-phase-docs | superseded | The pages it covered were deleted in 0000005 |
| ADR-001 | Keep the Vite stack and test with the Node test runner | 0000005-ravintio-docs-rewrite | active | Tests use `node --test` with no new dependency |
| ADR-002 | site-content owns the page Markdown | 0000005-ravintio-docs-rewrite | active | `src/site-content/` owns the pages, and `web-app` reads them |
| ADR-003 | Group the nav manifest into sections with slug file names | 0000005-ravintio-docs-rewrite | active | Three labelled sections, and page files named by slug |
| ADR-004 | Guard against the earlier brand with an allowlisted test | 0000005-ravintio-docs-rewrite | active | A test fails on the earlier brand outside history paths |
| ADR-005 | Verify reference pages against the installed pack | 0000005-ravintio-docs-rewrite | active | A test fails when a reference page and the pack differ |

---

## Status Definitions

| Status | Meaning |
|--------|---------|
| active | Decision stands. Implementation follows it. |
| superseded | A later ADR replaced it. |
| amended | The core decision stands, but its conditions or scope changed. |

---

*Template: decisions-index.template.md*
