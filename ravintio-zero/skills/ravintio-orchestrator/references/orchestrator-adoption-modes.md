---
title: "Orchestrator reference: Adoption modes"
summary: "Adoption Modes and the Retrofit Scan: how the run picks a mode and what a retrofit scan records."
status: "active"
version: "1.0.0"
---
# Orchestrator reference: Adoption modes

> Moved verbatim from `SKILL.md`. Read this file before you act on the topic. The Pack Index in `SKILL.md` lists the trigger.

### Adoption Modes

The coaching conversation and the pipeline are the same in every mode. Only the starting point and version logic differ.

| Mode | Signal (priority order, highest first) | Version | Coaching start |
|------|----------------------------------------|---------|----------------|
| External Anchor | 1: `ravintio-overrides/instructions/external-versioning.md` exists | Ask the human per the external constraint. Never suggest from run type alone. | Merge the constraint into coaching as additional rules. |
| Standard Iterative | 2: `plan/_archive/` has a feature dir, or `docs/about.md` exists | Minor bump by default | Prior decisions are constraints unless an ADR supersedes them. |
| Retrofit | 3: source exists in `src/` with no archive or overrides | Suggest from project markers, human confirms | Run the retrofit scan below first. |
| Greenfield | 4: none of the above | Start at `0.1.0` | Coach from the feature brief directly. |

Never combine signals. If the human states a mode that conflicts with the detected signal, warn once with the consequence, proceed if they confirm, and record the confirmed mode in the build log.

`discovery.md` is fresh every run and archived at ship. Its shared header covers the adoption-mode result with its signal, the git pre-flight findings, and the skills-inbox scan. Prior runs' discovery is read from `plan/_archive/` and `docs/`, never from a leftover file.

#### Retrofit Scan

For retrofit mode, scan the codebase and record in `discovery.md`:

- Version markers: `package.json`, `go.mod`, git tags, README
- Entry points and how the system starts
- Components and their boundaries
- Data ownership: which code writes which data
- API contracts, explicit or implied
- Established patterns and conventions
- Visible tech debt
