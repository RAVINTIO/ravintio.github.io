# Risk - web-app

| ID | Risk | Likelihood | Impact | Status |
|----|------|-----------|--------|--------|
| R-001 | The manifest and the page files fall out of step | Medium | Medium | Mitigated. The build fails on a missing page and warns on an unlisted one. |
| R-002 | The earlier product brand returns in a file | Low | Medium | Mitigated. `tests/brand-guard.test.mjs` fails on any match outside the allowlist. |
| R-003 | Reference pages drift from the `ravintio-zero/` pack | High | Medium | Mitigated. `tests/reference-match.test.mjs` fails on any missing or extra item. |
| R-004 | Vite dev-server advisories | Low | None in production | Open. Dev-only exposure. |
| R-005 | `scroll-margin-top` is fixed at 72px to match the nav height | Low | Low | Open |
