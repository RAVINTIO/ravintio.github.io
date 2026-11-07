# Security Report - site-quality-fixes

**Skill:** [validate-and-accept](../skills/ravintio-validate-and-accept/SKILL.md)
**Feature:** 0000027-site-quality-fixes
**Version:** 0.7.0

> It is advisory - no code changes are made. All findings require human review before action.

## Summary

**Overall Risk Assessment:** low
**Components Reviewed:** web-app, site-content
**Review Scope:** code review, dependency audit, IaC review

The review covers `git diff 1a054e5..HEAD -- src .github`. It finds no critical, high, or medium issue. Two low findings and six informational findings remain. The diff adds one dev dependency, one preview-only server plugin, and SHA pins for six actions. No workflow permission changed.

## Findings

| ID | Severity | Category | Component | Description | Recommendation | Status |
|----|----------|----------|-----------|-------------|----------------|--------|
| S-001 | low | config | web-app | `src/web-app/vite.config.ts:15-41` serves `dist/404.html` for missing paths. The plugin decodes the request path and resolves it against `dist`. The guard at line 32 (`!target.startsWith(dist + sep)`) passes any path outside `dist` to the normal static handler. The plugin never reads outside `dist`, because its only file read is `dist/404.html` (line 35). Only the local preview server and CI load the plugin. | None needed. Keep the guard if the plugin changes. | mitigated |
| S-002 | low | config | web-app | `src/web-app/vite.config.ts:35` calls `readFileSync` on `dist/404.html` with no existence check. If the file is missing, the preview server returns a 500 for each missing path. This is a robustness fault in a local test server, not an exposure. | Fixed in P3. The plugin now checks that `dist/404.html` exists and falls through to the default 404 otherwise. | mitigated |
| S-003 | informational | config | web-app | `src/web-app/404.html:5` sets `<base href="/">`. Relative links such as `./index.html` (line 41) and `img/ravintio-logo.png` (line 41) then resolve from the domain root at any URL depth. The base tag also changes fragment links. The skip link `#content` (line 36) resolves to `/#content`, so it leaves the 404 page and lands on the homepage. The base value is a static string, so the tag adds no way to load a foreign origin. | Check the skip link on the deployed 404 page. Use `#content` with a full path or a script if it must stay on the page. See A-001 for the project-page case. | open |
| S-004 | informational | data-exposure | web-app | `src/web-app/404.html` holds only static public content. It reads the `localStorage` key `ravintio-theme` (line 13) inside a try block and accepts only `light` or `dark`. No user input reaches the DOM, and the page sets no cookie. | None | mitigated |
| S-005 | informational | data-exposure | web-app | `src/web-app/404.html:28-30` loads fonts from `fonts.googleapis.com` and `fonts.gstatic.com`. Each 404 visit sends the visitor IP address to Google. `index.html` already does the same, so the change adds no new third party. | Self-host the fonts if the privacy position requires it. | accepted |
| S-006 | informational | config | web-app | External links keep `target="_blank" rel="noopener noreferrer"`. This holds in `src/web-app/404.html:55,83`, `src/web-app/index.html:53,120`, and `src/web-app/scripts/build-docs.js:118,136`. The new organisation URL is a static constant at `build-docs.js:14`. | None | mitigated |
| S-007 | informational | injection | web-app | `src/web-app/scripts/build-docs.js:163-165` adds `tabindex="0"` to code blocks. The language class and the code text both pass through `escapeHtml`, so the change adds no injection point. The attribute is a constant. | None | mitigated |
| S-008 | informational | config | web-app | `src/web-app/tests/e2e/axe.spec.ts` and `axe-report.ts` run only under Playwright against `localhost:4173`. They write `test-results/axe-report.json` locally. The site-tests workflow uploads only `playwright-report`, and only on failure (`.github/workflows/site-tests.yml:44-50`). | None | mitigated |

No credential appears in the diff. A scan of the diff and of tracked files for key, token, password, and private-key patterns found no secret. The only hits were a CSS comment that mentions a "muted token" and a retired-flag test fixture in `ravintio-zero/tests/test-0000196-req-002-retired-flags-fail.ps1:29`. The fixture uses a `.invalid` placeholder host. No `.env`, `.pem`, or `.key` file is tracked.

## Workflow review

| Check | Result |
|-------|--------|
| SHA pins | `deploy.yml:27,30,45,48,63` and `site-tests.yml:20,23,46` each pin a 40-character commit and keep the tag as a comment. The six actions are `checkout`, `setup-node`, `configure-pages`, `upload-pages-artifact`, `deploy-pages`, and `upload-artifact`. |
| Permissions | Unchanged. `deploy.yml:8-11` keeps `contents: read`, `pages: write`, and `id-token: write`, which Pages deployment needs. `site-tests.yml:8-9` keeps `contents: read`. |
| Triggers | Unchanged. Deploy runs on push to `main` and manual dispatch. Tests run on pull requests. |
| Install step | Both workflows use `npm ci`, so the lockfile controls versions. |
| Pin accuracy | P2 resolved all six SHAs with `gh api repos/actions/{repo}/commits/{tag}`, and each matches its tag. R-005 is mitigated. |

## Dependency Audit

| Package | Current Version | Known CVEs | Severity | Action Required |
|---------|----------------|------------|----------|----------------|
| `@axe-core/playwright` (dev) | 4.14.0, pinned exactly in `package.json` | none | none | none |
| `axe-core` (transitive) | 4.14.0 | none | none | none |
| All `src/web-app` packages | `npm audit` and `npm audit --omit=dev` both report 0 vulnerabilities | none | none | none |

Both axe packages carry the MPL-2.0 licence, per the lockfile entries. MPL-2.0 is a file-level copyleft licence. The site uses the packages only in dev tests and does not ship or modify them, so the licence adds no obligation. Both come from the Deque Systems axe-core project, which publishes regular releases. The lockfile records registry URLs and integrity hashes. Neither package reaches the built site.

## Threat Model

| Threat | Attack Vector | Affected Component | Likelihood | Impact | Existing Mitigation | Gap |
|--------|--------------|-------------------|------------|--------|--------------------|----|
| Path traversal through the preview plugin | A request such as `/..%2f..%2fetc/passwd` | web-app preview server | low | low | Decoding, path resolution, and the `dist` prefix guard at `vite.config.ts:32`. The server runs locally and in CI only. | None |
| Supply-chain tamper of an action tag | A moved upstream tag runs new code in CI | `.github/workflows` | low | medium | SHA pins in `deploy.yml` and `site-tests.yml` | `ravintio.yml:18` is unpinned (backlog 0000036) |
| Malicious dev dependency | A compromised release of the axe package | web-app dev tooling | low | medium | Exact version, lockfile integrity hash, `npm ci`, clean audit | No Dependabot config |
| Broken assets on a nested deployment | The site moves off the domain root | web-app 404 page | low | low | ADR-003 records the root assumption | See S-003 and A-001 |

## Risk register cross-reference

| Risk | State |
|------|-------|
| R-001 axe finds colour contrast violations | open. It is a quality risk with no security impact. The behaviour review covers the `style.css` fixes. |
| R-002 axe flags the Mermaid SVG | open. It is a quality risk with no security impact. The diff adds no rule exclusion. |
| R-003 narrower padding crowds code blocks | open. It is a layout risk with no security impact. |
| R-004 shared `dist/` and port | mitigated. The concurrency plan runs each Playwright unit in its own batch. |
| R-005 SHA pin resolves to the wrong commit | mitigated. All eight `uses:` lines carry a 40-character SHA and a tag comment. P2 resolved each SHA against its upstream tag, and all match. |
| R-006 pinned actions fall behind | open. The tag comments support manual bumps, but the repository has no Dependabot config. |
| R-007 404 page breaks off the domain root | open. `404.html:5` hard-codes `/`. ADR-003 records the assumption, and the nested-path test covers it. |

## Recommendations

1. Done in P2: each pinned SHA matches its upstream tag, which closes R-005.
2. Pin `actions/checkout@v4` at `.github/workflows/ravintio.yml:18` in the pack's workflow source (backlog 0000036).
3. Add `.github/dependabot.yml` for the `github-actions` and `npm` ecosystems, so pins and dev dependencies stay current (R-006).
4. Check that the skip link on the deployed 404 page reaches the 404 content (S-003).
5. Done in P3: the preview plugin checks that `dist/404.html` exists (S-002).

## Top actions before production

Do recommendation 1 before merge. The other items can follow the merge.
