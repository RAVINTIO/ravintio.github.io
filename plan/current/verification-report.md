# Verification report - 0000027-site-quality-fixes

## What ran

- `npm run build` in `src/web-app`, then `npx vite preview --port 4174 --strictPort`.
- A Node script with Playwright Chromium drove the preview. It read the homepage, the 404 page, all ten manifest pages, and the sitemap.
- The same script ran an `@axe-core/playwright` scan with the five WCAG 2.2 AA tags on three pages plus the 404 page, in both themes.
- `npx playwright test tests/e2e/axe.spec.ts` ran on port 4173 with its own server.
- The workflow pins were checked against the GitHub API with `gh api`.
- The preview server stopped at the end of the run.
- Two temporary changes proved the failure and report paths. Both were undone. `git diff` shows no change to `src/style.css`, and a rebuild restored `dist/`.

## Per criterion

| Criterion | Method | Outcome | Evidence |
|-----------|--------|---------|----------|
| US-001 AC-1 | Command: axe spec. Browser: own axe scan | verified | The spec ran 26 tests, 13 pages in light and dark, and all passed. It checks that `data-theme` matches the requested theme. My own scan of the homepage, sitemap, pipeline page, and 404 page found 0 violations in either theme. |
| US-001 AC-2 | Temporary regression in `src/style.css` | verified | I put `opacity: 0.4` back on `.doc-pagination__title` and rebuilt. The spec failed for the pipeline page in light and dark. The message read "color-contrast (serious)" and named `.doc-pagination__prev > .doc-pagination__title` and its next-link twin. After I restored the file, all 26 tests passed. |
| US-001 AC-3 | Command: axe spec. Temporary markup change | verified | `test-results/axe-report.json` exists after the spec runs. It holds an empty array because the site has no moderate or minor findings. I added a mismatched `xml:lang` to the built 404 page to prove the listing. The report then held two entries, one per theme. Each named the page, theme, rule `html-xml-lang-mismatch`, impact `moderate`, and node. A rebuild removed the change. |
| US-002 AC-1 | Browser read of the 404 page | verified | The page has one `<h1>` reading "Page not found" and a site header with the code link. It has a title, a unique meta description, and `<base href="/">`. Its main links go to `./index.html` and `./docs/sitemap.html`. Clicking them landed on `/index.html` and `/docs/sitemap.html`. |
| US-002 AC-2 | Browser load of `/docs/missing/page.html` | verified | The preview answered with status 404 and the 404 page. The stylesheet and script both loaded from `/assets/`, and the page applied two stylesheets. The only failed response was the document itself. |
| US-003 AC-1 | Browser read of the homepage, keyboard check | verified | The homepage has one `<main id="content">` with no other `#content` element. The first Tab stop is the skip link with `href="#content"`. The site header sits outside `<main>`. On the homepage and on a doc page, activating the skip link leaves the URL hash empty. The same happens on both, so the cause is the shared script and not this change. |
| US-003 AC-2 | Browser count across all pages | verified | All 13 paths (homepage, 404, sitemap, ten manifest pages) hold exactly one `<main>`. |
| US-004 AC-1 | Browser measure at 390 by 844 | verified | `main h1` spans 332.6 px on the sitemap and all ten manifest pages. `main p` measures 332.6 px on the ten manifest pages. The homepage and 404 page measure 326 px, and the criterion does not cover them. |
| US-004 AC-2 | Browser read of `scrollWidth` at 390 | verified | `scrollWidth` equals `clientWidth` at 390 px on the 13 pages. No page scrolls sideways. |
| US-005 AC-1 | File read, `gh api` check | verified | The 5 `uses:` lines in `deploy.yml` and 3 in `site-tests.yml` each hold a 40-character SHA with a tag comment. For `checkout` v5, `setup-node` v5, `configure-pages` v5, `upload-pages-artifact` v4, `deploy-pages` v4, and `upload-artifact` v4, the SHA matches what `gh api repos/actions/{name}/commits/{tag}` returns. |
| US-005 AC-2 | Command, with a temporary unpinned line | verified | The orchestrator replaced the `configure-pages` SHA in `deploy.yml` with the tag `v5`. `site-tests-workflow.test.mjs` exited 1 and named `deploy.yml:45`. The restore left `git diff` empty. |
| US-006 AC-1 | Browser read of header and footer links | verified | On the homepage, 404 page, and all ten manifest pages, the header code link and the footer **GitHub** link both use `https://github.com/RAVINTIO`. |
| US-006 AC-2 | Browser read of the header link | verified | The header link's `aria-label` and `title` both read "RAVINTIO on GitHub" on the homepage, 404 page, and doc pages sampled (`pipeline`, `skills`). |
| US-007 AC-1 | Read of built `dist/docs/project-operations.html` | verified | The `ravintio.yml` row cell reads "The CI gate works only after you commit it." The built page holds no "only works once committed". |

## Failures and findings

- No criterion failed.
- I filed no backlog entry.

## Not verifiable

- None. The orchestrator verified US-005 AC-2 after the first pass.
