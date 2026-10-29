# Changelog (0000005-ravintio-docs-rewrite, 29 Oct 2026)

**Feature:** RAVINTIO docs rewrite
**Version:** 0.4.0
**PR:** pending. The human pushes the branch and raises the PR (local git only).

## What changed

- Replaced every page with ten new pages in three sections: RAVINTIO, Zero, and Reference.
- Added the `site-content` component at `src/site-content/`. It owns the pages. Deleted both old content folders.
- Changed the nav manifest to labelled sections, with slug file names. Vite reads its inputs from the manifest.
- Added the supplied RAVINTIO logo, a wordmark, a new favicon set, and teal brand colours with AA contrast.
- Rewrote the homepage, the repo README, the living docs, and both components' docs.
- Added seven site tests run by `npm test`, with no new dependency.
- Loaded `mermaid` only on pages with a diagram.
- Stopped committing generated HTML and `sitemap-data.json`.
- Replaced the PowerShell refresh helper with `refresh-ravintio-zero-dir.ps1`.

## Why

The site carried an earlier brand and described tracks the pack no longer has. Developers who use coding agents need one site that explains RAVINTIO and teaches them to adopt RAVINTIO Zero.

## Deviations

- The brand guard allowlist gained `plan/current/`, recorded in ADR-004.
- Page 2 gained a "How the tools relate" section to meet REQ-001 in full.
- P2 ran U1 inline, merged batches 2 and 3, and used the primary tier for page writers. The build log records why.

## Validation results

- 21 of 21 tests pass. Build passes in 2.5 s.
- A browser check passed at 1280 px and 360 px in both themes, after one fix for a long code name on narrow screens.
- No critical or high security finding is open. Backlog `0000007` tracks the dev-dependency advisories.
- Waiting on a human: the private-content checklist for pages 1 and 2, and confirmation that RAVINTIO Framework's repo is public.

## Skipped phases

None

---

---
title: "Iteration Log - 0000005-ravintio-docs-rewrite"
summary: "Execution log for the agent session."
status: "active"
version: "0.1.0"
---
# Iteration Log - 0000005-ravintio-docs-rewrite

> **Audience:** The ship phase's build assessment (P4) and post-run technical review. This is NOT the PR changelog.

**Skill:** [implement](../skills/ravintio-implement/SKILL.md)
**Date:** 2026-10-29

## Iteration Steps Completed

| Phase | Status | Gate Result | Notes |
|-------|--------|-------------|-------|
| P0 - Discovery | pass | Design confirmed: yes | 13 coaching exchanges, Scope Lock complete |
| P1 - Plan | pass | All artifacts produced: yes | 5 ADRs, consistency check clean on first run |
| P2 - Implement | pass | Implementation complete: yes | 5 departures recorded in the build log |
| P3 - Validate and Accept | pending | | |
| P4 - Ship | pending | | |

## Requirement Changes During Run

| Change | Phase Active | Classification | Action Taken |
|--------|-------------|----------------|-------------|
| Brand guard allowlist gains `plan/current/` | P2 | cosmetic | ADR-004 updated in the same commit |
| Page 2 gains a "How the tools relate" section | P2 | additive, within REQ-001 | Added to meet the existing functional requirement |

## Self-Correct Log

- U1 tests went RED with 8 of 9 failing, then GREEN after the build, nav, and logo changes.
- The brand guard failed on repo docs until U2 rewrote them. It then passed.
- A fresh-context review found 20 issues across the ten pages. Two fix units applied them. The full suite stayed green.

## Quirks

- Generated `src/web-app/docs/*.html` and `public/sitemap-data.json` are no longer committed. `.gitignore` covers them.
- Asset and favicon paths are relative so the site works under `/ravintio-docs/`.

## Recommended Improvements

- Confirm that `github.com/RAVINTIO/ravintio-framework` is public before merge (A-003).
- Two errors in the `ravintio-zero` pack belong upstream. `pipeline-reference.md` miscounts skills, and the `product.template.yml` header understates when `product.yml` is needed.
