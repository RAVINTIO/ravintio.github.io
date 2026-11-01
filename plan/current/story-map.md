---
title: "Story Map - 0000016-site-regression-and-quality"
summary: "The backbone of activities and steps, with the requirement that covers each step."
---
# Story Map - 0000016-site-regression-and-quality

> Each row is one step under an activity. The Requirement cell names a requirement or a gap.

## Backbone

| Activity | Step | Story | Requirement |
|----------|------|-------|-------------|
| Read the site | Open a page in the chosen theme with no light frame | US-006 | REQ-006 |
| Change the site | Run the browser suite locally against a build | US-001 | REQ-001 |
| Change the site | See that every page loads, links resolve, and nothing scrolls sideways on a phone | US-001 | REQ-001 |
| Change the site | See that the theme toggle, page list, and diagrams still work | US-002 | REQ-002 |
| Change the site | Use Playwright MCP from the repo's own config | US-004 | REQ-004 |
| Review a pull request | See both suites pass or fail on the pull request | US-003 | REQ-003 |
| Review a pull request | Open the Playwright report when a test fails | US-003 | REQ-003 |
| Review a pull request | Block a merge on a failed check | none | gap: out of scope |
| Run the pipeline | Get a quality report in P3 of every run | US-005 | REQ-005 |
| Run the pipeline | See fix-now findings fixed in the run and the rest filed to the backlog | US-005 | REQ-005 |
| Run the pipeline | Scan pages with axe-core | none | gap: out of scope |
| Read Framework docs | Read full user docs for Framework | none | gap: out of scope |

## Gaps

- Block a merge on a failed check: a required check is a GitHub branch protection setting for the human. The design puts it out of scope.
- Scan pages with axe-core: backlog `0000015`.
- Read full user docs for Framework: backlog `0000014`. Framework is under major rework.
