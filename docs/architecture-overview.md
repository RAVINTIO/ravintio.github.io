# Architecture Overview

> Living document. Reflects current system state. Updated after every pipeline run.
> Do not archive this file. Update it in place.

Last updated: 0000016-site-regression-and-quality

---

## System Summary

The RAVINTIO docs system is a static site on GitHub Pages at `https://ravintio.github.io`. Authors write Markdown pages. A Node script turns them into HTML at build time, and Vite bundles the result. GitHub Actions runs both test suites on each pull request and deploys the site when a change merges to `main`. The system has no backend, no sign-in, and no stored user data.

---

## Components

| Component | Type | Purpose | Status |
|-----------|------|---------|--------|
| `site-content` | content | Owns the Markdown pages | active |
| `web-app` | static site | Builds and serves the site, owns the nav manifest and tests | active |

---

## Communication Patterns

```mermaid
flowchart LR
    pages["src/site-content/pages/\n(Markdown)"]
    manifest["docs.manifest.json\n(sections and order)"]
    build["web-app build-docs.js"]
    vite["Vite bundler"]
    dist["dist/\n(static HTML)"]
    pagesHost["GitHub Pages"]

    pages -->|"read at build time"| build
    manifest --> build
    build -->|"generates HTML"| vite
    vite -->|"bundles"| dist
    dist -->|"deployed by GitHub Actions"| pagesHost
```

---

## Data Ownership

| Data Store | Owner | Consumers |
|------------|-------|-----------|
| `src/site-content/pages/*.md` | `site-content` | `web-app`, read only at build time |
| `src/web-app/docs.manifest.json` | `web-app` | `web-app` build script and Vite config |

---

## External Dependencies

| Dependency | Type | Components That Use It |
|------------|------|----------------------|
| GitHub Pages | hosting | `web-app` |
| GitHub Actions | CI/CD | `web-app`, through `deploy.yml` and `site-tests.yml` |
| Vite 7 | npm | `web-app` |
| marked 17 | npm | `web-app` |
| mermaid 12 | npm | `web-app`, loaded only on pages with diagrams |
| Playwright 1.64 | npm, dev | `web-app` regression suite, on Chromium |
| Playwright MCP 0.0.83 | agent tool | The P3 quality review, declared in `.mcp.json` |

---

## Key Architectural Decisions

See `docs/decisions-index.md` for the full list. These decisions shape the current architecture:

- Static site generation with Vite, with no backend (website ADR-001).
- `site-content` owns the pages, and `web-app` only reads them (0000005 ADR-002).
- A sectioned manifest sets the nav sections and page order (0000005 ADR-003).
- A native `<details>` disclosure holds the page list. It closes on narrow screens and shows as a sidebar on wide ones (0000009 ADR-002).
- Tests guard the brand and keep the reference pages in step with the pack (0000005 ADR-004 and ADR-005).
- A Playwright suite on Chromium tests the built site beside the Node content suite (0000016 ADR-001).
- `site-tests.yml` runs both suites on each pull request (0000016 ADR-002).
- A repo capability skill reviews site quality in P3 of every run (0000016 ADR-003).
- An inline script sets the theme before first paint (0000016 ADR-004).

---

*Template: architecture-overview.template.md*
