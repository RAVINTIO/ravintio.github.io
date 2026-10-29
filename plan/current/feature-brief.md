---
title: "Feature Brief - ravintio-docs-rewrite"
summary: "The business case, scope, and product requirements for the feature."
status: "approved"
version: "0.4.0"
---
# Feature Brief - ravintio-docs-rewrite

**Feature ID:** 0000005-ravintio-docs-rewrite

## Business Goal

The docs site still presents an earlier brand and documents tracks the pack no longer has. Developers who use coding agents need one site that explains RAVINTIO and teaches them to adopt RAVINTIO Zero. This run replaces every page with new content under the RAVINTIO name at `ravintio.github.io/ravintio-docs`.

## Features

| Feature | User Stories | Priority | Wave |
|---------|-------------|----------|------|
| RAVINTIO overview | As a developer evaluating agent tooling, I read what RAVINTIO is and what each of its six tools does, so that I can pick the tool that fits my problem. | must-have | 1 |
| Zero adoption guide | As a developer adopting Zero, I follow the install and first-run guides, so that I can take a first feature to a pull request using only the site. | must-have | 1 |
| Zero reference | As a Zero user, I look up a skill, standard, or template, so that I can check what the pack provides. | must-have | 1 |
| Brand and structure | As a reader, I find the site under the RAVINTIO name and logo with no trace of the earlier brand, so that the product reads as one thing. | must-have | 1 |

## Waves

| Wave | Features Included | Ships When |
|------|-------------------|------------|
| 1 | All four | All seven acceptance criteria pass and the human accepts |

## Target Architecture

### Components

| Component | Type | New or Existing | Responsibility |
|-----------|------|-----------------|---------------|
| site-content | component-pack | new | Owns the Markdown pages and their component docs |
| web-app | microfrontend | existing | Builds the static site, owns the nav manifest, styling, logo, and favicons |

### Data Ownership

| Data Store | Owner Component | Shared With |
|------------|----------------|-------------|
| `src/site-content/pages/*.md` | site-content | web-app (read only, at build time) |
| `src/web-app/docs.manifest.json` | web-app | none |

### Integration Points

| From | To | Method | Contract |
|------|-----|--------|----------|
| web-app | site-content | File read at build | `build-docs.js` reads every page listed in `docs.manifest.json` from `src/site-content/pages/` |

## Stack

| Concern | Decision |
|---------|----------|
| Language | TypeScript, JavaScript (Node build scripts), Markdown |
| Runtime | Node 24 |
| Framework | Vite 7 |
| Frontend | Static HTML from `marked`, diagrams from `mermaid` |
| Database | none |
| ORM | none |
| Testing | Node built-in test runner (`node --test`) |
| IaC | none |
| Cloud | GitHub Pages |
| Compute | none (static hosting) |
