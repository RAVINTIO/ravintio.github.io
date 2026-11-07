# Acceptance evidence - 0000027-site-quality-fixes

## Checks

| Check | Result |
|-------|--------|
| Library audit | pass. `@axe-core/playwright` 4.14.0 is on no avoid list. |
| Semantic coverage | 14 of 14 criteria map to a named test |
| Typecheck (`tsc --noEmit`) | pass |
| Build | pass |
| Unit tests (`npm test`) | 93 of 93 pass |
| Browser tests (`npx playwright test`) | 92 pass, 1 existing skip, 0 fail |
| Axe scan | 26 of 26 page and theme pairs pass. No moderate or minor finding. |
| `npm audit` | 0 vulnerabilities |
| Self-correct cycles | 1 for CI: two test titles named their criteria. 1 fix-now quality finding fixed. |

## Security

Overall risk: low. No critical, high, or medium finding. See `security-report.md`.

- S-001: the 404 preview plugin guards against path traversal (`src/web-app/vite.config.ts:32`). Mitigated.
- S-002: the plugin now checks that `dist/404.html` exists. Fixed in P3.
- S-003: `<base href="/">` sends the 404 skip link to `/#content` with JavaScript off. Filed as backlog 0000037.
- All six action SHAs match their upstream tags (R-005 mitigated).

## Execution

A Playwright script drove the local preview in both themes. It read the homepage, the 404 page at a nested missing path, the sitemap, and all ten doc pages. All 14 criteria are verified, with none `not-verifiable`. The failure paths were proved by temporary breaks:

- A low-contrast pagination title failed the axe scan and named `color-contrast`.
- An unpinned action failed the workflow test and named `deploy.yml:45`.

See `verification-report.md`.

## Site quality review

14 pages reviewed at 390 px and 1280 px in both themes. One fix-now finding, fixed in `7b8fb25`:

- A-001: the skip link scrolled to the content but left focus on the link, which fails WCAG 2.4.1. `main.ts` now moves focus to the target.

New backlog entries:

- 0000037: the 404 skip link with JavaScript off. This run caused it, so the review's rule sorts it as fix-now. It stays in the backlog because no `href` keeps the reader on the same URL in both cases.
- 0000038: inline code in table cells breaks mid-word at 390 px.
- 0000036: pin the checkout in the pack's `ravintio.yml` source, from the security review.

Backlog 0000018, 0000019, and 0000020 are verified fixed. See `site-quality-report.md`.

## For the reviewer

- The 404 page copy and the "RAVINTIO on GitHub" label are agent-drafted (`src/web-app/404.html`, `src/web-app/index.html:53`).
- `vite.config.ts` adds a preview plugin, because Vite 7 preview has no 404 page support. It affects local preview and CI only.
- The suite now fails a pull request on any serious or critical axe violation (0000027 ADR-002).
- Each code `<pre>` takes keyboard focus, so Tab now stops on each code block (`src/web-app/scripts/build-docs.js`).
