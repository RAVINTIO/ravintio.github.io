---
title: "Backlog Entry: 0000004 - Rename to RAVINTIO docs"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future discovery run."
status: "open"
---
# Backlog Entry: 0000004 - Rename to RAVINTIO docs

**Source feature:** none (human request)
**Source phase:** none (human request)
**Deferral source:** human request
**Date filed:** 2026-10-24

---

## Problem

The GitHub org is now `RAVINTIO`. This repo still uses Planifest: the `planifest-docs/` folder and its `p0NN-planifest-*.md` file names, prose, the installed `planifest-framework/` pack, and the repo name `planifest-docs`. The Pages site moved to `ravintio.github.io` with the org.

## Suggested Action

Rename the brand, folders, and file names to RAVINTIO. Upgrade the installed pack once RAVINTIO Framework ships its rename. After merge, run `gh repo rename ravintio-docs`. Then update the README links in `RAVINTIO/ravintio-zero`, which still name `planifest-docs` and its file names.

## Reference

RAVINTIO Zero did the same rename in feature 0000160 (v1.0.0, PR #25 in `RAVINTIO/ravintio-zero`). Its ADRs and build report are in `plan/_archive/0000160-ravintio-rebrand-2026-10-24/` in that repo. Lessons from that run:

- Protect history ids, sibling repo names, and split literals such as `"planifest""-framework"` from the bulk replace.
- Leave `plan/_archive/`, `plan/changelog/`, and applied migrations as written.
- Add a brand guard test with a path and line allowlist.
- Run the Bash suites under Bash 5 or in CI. macOS Bash 3.2 hides lines from `done < <(grep ...)` loops.
