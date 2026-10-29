# Risk - site-content

| ID | Risk | Likelihood | Impact | Status |
|----|------|-----------|--------|--------|
| R-001 | Private strategy content reaches a page | Medium | High | Mitigated by a human checklist review at P3 of each run |
| R-002 | Reference pages drift from the pack | High | Medium | Mitigated. `reference-match.test.mjs` fails on any difference. |
| R-003 | A page describes a pack behaviour that has changed | Medium | Medium | Open. Review the Zero pages when the pack updates. |
