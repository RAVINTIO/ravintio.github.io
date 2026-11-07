---
title: "Domain Glossary - site-quality-fixes"
summary: "Definitions of domain terms used within this feature."
status: "active"
version: "0.1.0"
---
# Domain Glossary - site-quality-fixes

**Skill:** [plan](../skills/ravintio-plan/SKILL.md) (updated by any agent that introduces a new domain term)
**Feature:** 0000027-site-quality-fixes
**Version:** 0.7.0

## Terms

| Term | Definition | Aliases | Used In |
|------|-----------|---------|---------|
| Axe scan | One `@axe-core/playwright` analysis of one page in one theme. | accessibility scan | web-app tests |
| Impact | The axe severity of a violation: minor, moderate, serious, or critical. | severity | web-app tests |
| Axe report | `test-results/axe-report.json`, which lists moderate and minor violations for the P3 review. | none | web-app tests, P3 |
| Landmark | An HTML element, such as `<main>`, that a screen reader can jump to. | region | web-app |
| SHA pin | A `uses:` reference that names a full 40-character commit SHA instead of a tag. | pinned action | workflows |
| Organisation link | The header and footer link to `https://github.com/RAVINTIO`. | code link | web-app |
| 404 page | `dist/404.html`, which GitHub Pages serves for any missing path. | not-found page | web-app |
