---
title: "Domain Glossary - explainer-six-tools"
summary: "Definitions of domain terms used within this feature."
status: "active"
version: "0.1.0"
---
# Domain Glossary - explainer-six-tools

**Skill:** [plan](../skills/ravintio-plan/SKILL.md) (updated by any agent that introduces a new domain term)
**Feature:** 0000024-explainer-six-tools
**Version:** 0.6.0

## Terms

| Term | Definition | Aliases | Used In |
|------|-----------|---------|---------|
| Shared purpose | Visibility and governance over agentic software development. The six tools each serve it. | purpose | site-content, web-app |
| Explainer | The page `what-is-ravintio.md`. It introduces RAVINTIO and the six tools. | what is RAVINTIO | site-content |
| Tool entry | One H3 section per tool in the explainer's "The six tools" section. | entry | site-content, web-app tests |
| Meta description | The `<meta name="description">` text of a page, taken from the manifest `description` field. | page summary | web-app |
| Voice check | The test in `style.test.mjs` that flags "is", "are", "was", or "were" before a participle. | passive-voice check | web-app tests |
| Allowlist | The list of adjective phrases the voice check accepts, such as "are merged". | none | web-app tests |
