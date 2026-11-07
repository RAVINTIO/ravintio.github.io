# Risk - web-app

| ID | Risk | Likelihood | Impact | Status |
|----|------|-----------|--------|--------|
| R-001 | The manifest and the page files fall out of step | Medium | Medium | Mitigated. The build fails on a missing page and warns on an unlisted one. |
| R-002 | The earlier product brand returns in a file | Low | Medium | Mitigated. `tests/brand-guard.test.mjs` fails on any match outside the allowlist. |
| R-003 | Reference pages drift from the `ravintio-zero/` pack | High | Medium | Mitigated. `tests/reference-match.test.mjs` fails on any missing or extra item. |
| R-004 | Vite dev-server advisories | Low | None in production | Open. Dev-only exposure. |
| R-005 | `scroll-margin-top` is fixed at 72px to match the nav height | Low | Low | Open |
| R-006 | The first-frame test depends on paint order and turns flaky | Medium | Medium | Mitigated. The test reads the theme state before the module script runs, not a screenshot. |
| R-007 | A future Content Security Policy blocks the inline theme script | Low | Low | Open. Allow the script by hash (0000016 ADR-004). |
| R-008 | The site moves off the domain root and the 404 page loses its assets | Low | Medium | Open. `<base href="/">` assumes the root (0000027 ADR-003). |
| R-009 | Pinned actions fall behind security releases | Medium | Low | Open. The tag comment beside each SHA lets a maintainer or Dependabot bump it. |
| R-010 | A new page or style change adds a serious axe violation | Medium | Medium | Mitigated. `e2e/axe.spec.ts` fails the pull request. |
