# Repository structure

> The layout of this repo. RAVINTIO Zero manages it, so the layout follows the pack's conventions.

## Top-level folders

```
repo/
├── ravintio-zero/        ← The installed pack: skills, standards, templates, hooks, scripts
├── ravintio-overrides/   ← Repo-specific instructions and standards for the pack
├── plan/                 ← Feature runs, the archive, the changelog, and the backlog
├── src/                  ← One folder per component
├── docs/                 ← Living docs about the whole system
└── graphics/             ← Logo and favicon sources
```

Don't edit `ravintio-zero/` by hand. Refresh it from a Zero release instead.

## `plan/`

```
plan/
├── current/              ← The active run
│   ├── discovery.md      ← What the orchestrator found before coaching
│   ├── feature-brief.md  ← The confirmed brief
│   ├── design.md         ← The confirmed design
│   ├── build-log.md      ← The run's audit trail
│   ├── execution-plan.md ← Units, batches, and non-functional targets
│   ├── story-map.md      ← Activities, steps, and gaps
│   ├── scope.md, risk-register.md, domain-glossary.md
│   ├── requirements/     ← One file per user story
│   └── adr/              ← One file per decision
├── _archive/             ← Finished runs, as {feature-id}-{date}/
├── changelog/            ← One change record per feature
├── backlog/              ← Deferred work, one folder per entry, and the .next-id counter
└── state/                ← Setup flags per agent tool
```

Ship moves `current/` into `_archive/`. Nobody edits an archived run.

## `src/`

| Component | Holds |
|-----------|-------|
| `site-content/` | `component.yml`, the pages in `pages/`, and component docs in `docs/` |
| `web-app/` | `component.yml`, the build script, the nav manifest, styles, tests, and component docs in `component-docs/` |

Every component has a `component.yml` manifest. Its docs describe its purpose, interface, dependencies, risks, and quirks.

## `docs/`

| File | Holds |
|------|-------|
| `architecture-overview.md` | How the components fit together |
| `component-registry.md` | Every component, with links to its docs |
| `dependency-graph.md` | Which component reads from which |
| `decisions-index.md` | Every ADR across features |
| `system-context.md` | The system's place among people and external services |
