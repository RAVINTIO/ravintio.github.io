---
title: "Data Contract: site-content"
summary: "Defines the precise schema and relationships of data owned by this component."
status: "active"
version: "0.1.0"
---
# Data Contract - site-content

**Skill:** [implement](../skills/ravintio-implement/SKILL.md) (updated via migration proposals)
**Component:** site-content
**Feature:** 0000005-ravintio-docs-rewrite
**Owner:** site-content
**Schema Version:** 0.1.0

> This is the authoritative schema definition for this component's data. The data is a set of Markdown files, not database tables.

## Tables

### pages (files in `src/site-content/pages/`)

| Column | Type | Nullable | Default | Constraints |
|--------|------|----------|---------|------------|
| file name | kebab-case slug plus `.md` | no | none | unique, matches one `web-app` manifest entry |
| first heading | Markdown `#` line | no | none | exactly one per file, matches the manifest title |
| body | Markdown | no | none | see the invariants |

**Indexes:**
- `src/web-app/docs.manifest.json` (owned by `web-app`) orders the pages.

**Relationships:**
- Links between pages use relative `{slug}.md` or `{slug}.md#{anchor}` targets, rewritten to `.html` at build.

## Invariants

- No page names the earlier product brand.
- The brand appears as `RAVINTIO` in block capitals outside code and URLs.
- Reference pages name each pack item in code font in a `###` heading or a first table column.
- Every prose sentence stays under 25 words.

## Migration History

| ID | Version | Description | Status | Destructive |
|----|---------|------------|--------|------------|
| M-001 | 0.1.0 | Initial page set | applied | no |
