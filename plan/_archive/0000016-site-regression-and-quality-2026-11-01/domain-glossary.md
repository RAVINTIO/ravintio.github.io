---
title: "Domain Glossary - site-regression-and-quality"
summary: "Definitions of domain terms used within this feature."
status: "active"
version: "0.1.0"
---
# Domain Glossary - site-regression-and-quality

**Skill:** [plan](../skills/ravintio-plan/SKILL.md) (updated by any agent that introduces a new domain term)
**Feature:** 0000016-site-regression-and-quality
**Version:** 0.5.0

## Terms

| Term | Definition | Aliases | Used In |
|------|-----------|---------|---------|
| Regression suite | The Playwright tests in `src/web-app/tests/e2e/`. They load the built site in Chromium and check what only a browser can see. | browser suite, e2e suite | web-app |
| Content suite | The existing `node --test` tests in `src/web-app/tests/`. They read source and built HTML as text. | node suite | web-app |
| Quality review | The P3 step that runs the `site-quality-review` skill. It reviews the site through Playwright MCP and writes the quality report. | site review | pipeline |
| Quality report | `plan/current/site-quality-report.md`. It lists each finding by area, with its evidence and its sorting. | review report | pipeline |
| Fix-now finding | A review finding that the run fixes before it ships. The confirmed rule in REQ-005 decides it. | urgent finding | pipeline |
| First frame | The first frame the browser paints for a page, before the module script runs | first paint | web-app |
| White flash | A light first frame for a reader whose theme is dark | theme flash | web-app |
| Page list | The section nav that lists the doc pages, inside a `<details>` disclosure | section nav | web-app |
