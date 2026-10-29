---
title: "Domain Glossary - ravintio-docs-rewrite"
summary: "Definitions of domain terms used within this feature."
status: "active"
version: "0.1.0"
---
# Domain Glossary - ravintio-docs-rewrite

**Skill:** [plan](../skills/ravintio-plan/SKILL.md) (updated by any agent that introduces a new domain term)
**Feature:** 0000005-ravintio-docs-rewrite
**Version:** 0.4.0

## Terms

| Term | Definition | Aliases | Used In |
|------|-----------|---------|---------|
| RAVINTIO | The ecosystem of six independently usable open-source tools. The name abbreviates eight qualities. Always written in block capitals. | none | site-content, web-app |
| Tool | One of the six RAVINTIO products: Zero, Framework, Accept, Qualify, Insight, or Unbound | product | site-content |
| Status label | The fixed text that tells a reader whether a tool is available: "Available", "In design", or "In design, experimental research only" | none | site-content |
| Pack | The `ravintio-zero/` folder that Zero installs into a repo, holding skills, standards, templates, hooks, and scripts | install | site-content |
| Skill | An agent-facing instruction package in `ravintio-zero/skills/`, one folder with a `SKILL.md` | none | site-content |
| Standard | A rule document in `ravintio-zero/standards/` | none | site-content |
| Template | A starting file in `ravintio-zero/templates/` that a phase copies to write an artefact | none | site-content |
| Phase | One of the five pipeline stages, P0 Discovery to P4 Ship | stage | site-content |
| Nav section | A labelled group of pages in the site nav: RAVINTIO, Zero, or Reference | section | web-app |
| Earlier brand | The product name the site used before RAVINTIO. Tests refer to it, but no page names it. | none | web-app tests |
| Brand guard | The test that fails when the earlier brand appears outside allowlisted paths | none | web-app tests |
