---
title: "Pack Update Policy"
version: "1.0.0"
---
# Pack Update Policy

Canonical definition of how a `ravintio-zero/` dependency update is detected, confirmed, and trusted. This is the document backlog entries mean when they reference "the Pack Update Policy".

---

## What this covers

Distinguishes "the `ravintio-zero/` folder is being updated to a newer version" from "unrecognised code is being pushed from an unknown source." The two look identical at the file-diff level, both touch files under `ravintio-zero/`, but only the first is a trusted, provenance-tracked update, and only the first should be treated as such without question.

This policy is unrelated in scope to `ravintio-migrator`: that skill owns the narrower "read one pending migration file, present findings, apply confirmed changes, archive it" flow, and continues to be invoked from the same discovery area when a migration file happens to exist. This policy's detection-and-confirmation step runs first and independently, whether or not any migration accompanies the update.

## Where this runs

At the orchestrator's Resume Detection step (`ravintio-orchestrator/SKILL.md`), positioned alongside the existing migration-scan step, before any other discovery work, including ordinary feature-brief coaching Q&A. It is surfaced as its own distinct decision: never silently applied, and never conflated with that coaching flow.

## Detection signal

A candidate `ravintio-zero/` dependency update is detected when either of the following is true:

1. **Version mismatch**: the version declared in the installed `ravintio-zero/component.yml` differs from the previously recorded value (the version last read from `docs/about.md`, or from the most recent archived feature's `design.md`/`about.md`).
2. **Newer pack files present**: files under `ravintio-zero/` declare a version newer than the version this repo last ran a pipeline against.

Detection keys on new or changed files under `ravintio-zero/` since the last recorded pipeline run, not solely the version string in isolation: a repo that manually edited `component.yml`'s version field without an actual pack update is a known false-positive risk (ADR-002, Risks), and file-level change detection avoids it.

## Human confirmation gate

Detecting a candidate update is not sufficient to treat it as trusted. Every path through this policy terminates in one of two explicit outcomes; there is no implicit pass-through:

- **Explicit confirmation**, or
- **Explicit rejection.**

Confirmation requires the human to affirm both of the following, as two separate facts; a blanket "yes, update it" satisfies neither:

1. **That this is in fact a `ravintio-zero/` update**: as opposed to an arbitrary, unrelated code push that happens to touch the same paths.
2. **Its provenance**: the specific source release, commit, or migration identifier that produced the arriving files. The human must confirm a specific, named origin, not simply agree that an update is happening.

Record the outcome, confirmed with its stated provenance, or rejected, in `plan/current/build-log.md` before discovery proceeds. If rejected, the arriving `ravintio-zero/` files are treated as untrusted: do not act on them silently, and ask the human how to proceed.

## Relationship to `ravintio-migrator`

Unchanged by this policy. `ravintio-migrator` continues to own reading a single pending migration file, presenting its findings, applying confirmed changes, and archiving it. This policy's detection-and-confirmation step happens first, independent of whether a migration file exists; `ravintio-migrator` may still run afterward for any migration that accompanies the confirmed update.

## Related

- `ravintio-orchestrator/SKILL.md` Resume Detection: the discovery step invoking this policy.
