---
title: "Risk Register - site-quality-fixes"
summary: "Technical, operational, and security risks with their mitigations."
status: "active"
version: "0.1.0"
---
# Risk Register - site-quality-fixes

**Skill:** [plan](../skills/ravintio-plan/SKILL.md) (updated by any agent that identifies a new risk)
**Feature:** 0000027-site-quality-fixes
**Version:** 0.7.0
**Overall Risk Level:** low

## Risks

| ID | Category | Description | Likelihood | Impact | Mitigation | Status |
|----|----------|------------|------------|--------|-----------|--------|
| R-001 | technical | The first axe scan finds colour contrast violations in one theme. | medium | medium | Fix the colour tokens in `style.css` in both themes. | open |
| R-002 | technical | Axe flags the SVG that Mermaid renders. | medium | low | The scan waits for render. A rule exclusion needs human approval. | open |
| R-003 | technical | Narrower phone padding crowds code blocks and tables. | low | low | The 390 px sideways-scroll check guards every page. | open |
| R-004 | technical | Units that rebuild `dist/` and use preview port 4173 at once corrupt each other's test run. | medium | medium | The concurrency plan runs every Playwright unit in its own batch. | mitigated |
| R-005 | security | A SHA pin resolves to a commit other than the tag's. | low | medium | Read each SHA with `gh api repos/{owner}/{repo}/commits/{tag}` and keep the tag comment beside it. | open |
| R-006 | operational | Pinned actions fall behind security releases. | medium | low | The tag comments let a maintainer or Dependabot bump each pin. | open |
| R-007 | technical | The 404 page breaks if the site moves off the domain root. | low | medium | ADR-003 records the root assumption. AC-2 of REQ-002 tests a nested path. | open |

## Assumptions Logged as Risks

| ID | Assumption | Impact if Wrong | Status |
|----|-----------|----------------|--------|
| A-001 | The site serves from the root of `ravintio.github.io`. | `<base href="/">` breaks the 404 page assets. | open |
| A-002 | The first axe scan surfaces few serious violations. | REQ-001 grows past 4 points and may split through a mid-pipeline change. | open |
