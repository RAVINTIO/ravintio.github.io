---
title: "Risk Register - ravintio-docs-rewrite"
summary: "Technical, operational, and security risks with their mitigations."
status: "active"
version: "0.1.0"
---
# Risk Register - ravintio-docs-rewrite

**Skill:** [plan](../skills/ravintio-plan/SKILL.md) (updated by any agent that identifies a new risk)
**Feature:** 0000005-ravintio-docs-rewrite
**Version:** 0.4.0
**Overall Risk Level:** medium

## Risks

| ID | Category | Description | Likelihood | Impact | Mitigation | Status |
|----|----------|------------|------------|--------|-----------|--------|
| R-001 | security | Private strategy content reaches a public page, such as the implementation sequence or open questions | medium | high | Criterion 4 checklist review at P3. The strategy file is never copied into the repo. | open |
| R-002 | technical | The `ravintio-zero/` pack changes and the reference pages fall out of date | high | medium | The reference-match test fails the build on any mismatch | open |
| R-003 | compliance | The logo teal (about `#04A29F`) fails WCAG AA contrast as text or link colour on white | medium | medium | Use a darker teal for text and links. Check contrast ratios at P3. | open |
| R-004 | operational | Old inbound links to the earlier pages return 404 | high | low | Accepted by the human. No redirects. | accepted |
| R-005 | technical | The style test flags tables, lists, or code as long sentences | medium | low | The test strips code blocks, code spans, tables, and headings before it splits sentences | open |
| R-006 | technical | The brand guard matches its own source or allowlist and fails | medium | low | Build the search term from two parts in the test source, and allowlist the test file path | open |
| R-007 | operational | The deploy runs before the human renames the repo, so the site publishes at the old address | low | medium | The PR description tells the human to rename the repo before merge | open |
| R-008 | technical | The 490 KB logo pushes pages past the 300 KB weight target | high | medium | Serve a resized copy under 20 KB. The page-weight check runs at P3. | open |

## Assumptions Logged as Risks

| ID | Assumption | Impact if Wrong | Status |
|----|-----------|----------------|--------|
| A-001 | The human renames the GitHub repo to `ravintio-docs` before the first deploy | The site deploys to the old address and pushes to the new remote fail | open |
| A-002 | The installed `ravintio-zero/` pack matches the published Zero release | Reference pages describe a version readers don't install | open |
| A-003 | RAVINTIO Framework is publicly available at `github.com/RAVINTIO/ravintio-framework` | Its "Available" label misleads readers | open |
| A-004 | The logo PNG reads well on the dark theme | The header needs a light variant | open |
