---
title: "Story Map - 0000027-site-quality-fixes"
summary: "The backbone of activities and steps, with the requirement that covers each step."
---
# Story Map - 0000027-site-quality-fixes

> Each row is one step under an activity. The Requirement cell names a requirement or a gap.

## Backbone

| Activity | Step | Story | Requirement |
|----------|------|-------|-------------|
| Maintain the site | Open a pull request and let CI scan every page for accessibility | US-001 | REQ-001 |
| Maintain the site | Read the moderate and minor findings in the P3 review | US-001 | REQ-001 |
| Maintain the site | Trust that CI runs the action code reviewed at pin time | US-005 | REQ-005 |
| Maintain the site | Pin actions in `ravintio.yml` | none | gap: out of scope |
| Find a page | Follow a broken link and land on a site page | US-002 | REQ-002 |
| Find a page | Return to the homepage or the sitemap from the 404 page | US-002 | REQ-002 |
| Find a page | Follow the header or footer code link to the source of all six tools | US-006 | REQ-006 |
| Read a page | Jump to the homepage main content by landmark | US-003 | REQ-003 |
| Read a page | Read doc page text on a phone at a comfortable line length | US-004 | REQ-004 |
| Read a page | Read who acts in the project operations table | US-007 | REQ-007 |

## Gaps

- Pin actions in `ravintio.yml`: out of scope. `ravintio-zero/setup.sh` writes that file, so a setup refresh would undo any pin.
