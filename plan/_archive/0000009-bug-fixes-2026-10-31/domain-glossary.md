---
title: "Domain Glossary - bug-fixes"
summary: "Definitions of domain terms used within this feature."
status: "active"
version: "0.1.0"
---
# Domain Glossary - bug-fixes

**Skill:** [plan](../skills/ravintio-plan/SKILL.md) (updated by any agent that introduces a new domain term)
**Feature:** 0000009-bug-fixes
**Version:** 0.4.1

## Terms

| Term | Definition | Aliases | Used In |
|------|-----------|---------|---------|
| Page list | The section nav that lists the ten pages. It sits in the sidebar at desktop widths. | section nav, sidebar | web-app |
| Disclosure | The native `<details>` and `<summary>` pair that wraps the page list. The summary names the current page and toggles the list. | toggle | web-app |
| Agreed copy | Text the human confirmed in P0, stored in `plan/current/agreed-copy.md`. Pages use it verbatim. | none | site-content |
| Improvement loop | The P2 refactor cycle that runs after each test passes. It asks whether a simpler solution passes the same tests. | refactor loop | site-content |
| Advisory | A known vulnerability that `npm audit` reports for a dependency | vulnerability | web-app |
