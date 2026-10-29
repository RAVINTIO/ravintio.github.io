# Security Report - 0000005-ravintio-docs-rewrite

**Scope:** `src/web-app/` and `src/site-content/` on the feature branch.

## Findings

| Finding | Location | Severity | Mitigation |
|---------|----------|----------|------------|
| `dompurify` advisory (ADD_TAGS bypass), shipped in the browser bundle through `mermaid` | `src/web-app/package.json` (`mermaid` ^11.13.0) | Medium | Mitigated in practice. Mermaid renders only diagrams from repo pages, with `securityLevel: 'antiscript'` in `src/main.ts`. No reader input reaches it. Upgrade tracked in backlog `0000007`. |
| `mermaid` advisory (classDef HTML injection in state diagrams) | `src/web-app/package.json` | Medium | Same as above. Pages hold no state diagrams. |
| `vite` path traversal and other dev-server advisories | `src/web-app/package.json` (`vite` ^7.3.1) | Low | Dev server only. Production is static files. Backlog `0000007`. |
| Ten more transitive dev-dependency advisories (`lodash-es`, `postcss`, `picomatch`, and others) | `src/web-app/package-lock.json` | Low | Build-time only. `npm audit --omit=dev` reports none. Backlog `0000007`. |
| Code blocks render escaped HTML | `src/web-app/scripts/build-docs.js` `code()` renderer | Info | Fixed in this run. The old renderer passed code text through unescaped. |
| External links open in a new tab | `scripts/build-docs.js`, `index.html` | Info | Every `target="_blank"` link carries `rel="noopener noreferrer"` |

**Injection points:** the site takes no runtime input. Markdown comes from the repo and renders at build time.
**Credential handling:** no secrets in source. A pattern scan of `src/`, `docs/`, and `README.md` found none.
**Path traversal:** `build-docs.js` reads only files named in the manifest from one folder.
**Data exposure:** the site stores only the theme choice in `localStorage`, under `ravintio-theme`.
**Private content:** no text from the private strategy appears in the repo.

## Overall risk rating

Low. No critical or high finding is unmitigated.

## Risk register cross-reference

| Risk | Status after P3 |
|------|-----------------|
| R-001 private strategy content | Mitigated. The agent checklist passed, and human review is still due. |
| R-002 pack drift | Mitigated by `reference-match.test.mjs` |
| R-003 teal contrast | Mitigated. Text uses `#036b68` (light) and `#2dd4bf` (dark). |
| R-004 old links 404 | Accepted |
| R-005 style test false positives | Mitigated. No false positive seen. |
| R-006 brand guard self-match | Mitigated. The term splits in two parts. |
| R-007 deploy before repo rename | Open. The human renames the repo before merge. |
| R-008 logo weight | Mitigated. Served logo is 5 KB. |

## Top actions before production

1. Rename the GitHub repo to `ravintio-docs` before merging.
2. Confirm `github.com/RAVINTIO/ravintio-framework` is public (A-003).
3. Review the pages against the private-content checklist (criterion 4).
