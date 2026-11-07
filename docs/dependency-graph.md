# Dependency Graph

Last updated: 0000027-site-quality-fixes

---

## Build Pipeline

```mermaid
graph TD
    subgraph Source
        pages["src/site-content/pages/\n(Markdown)"]
        manifest["docs.manifest.json\n(sections, order, descriptions)"]
    end

    subgraph Build
        builder["scripts/build-docs.js\n(Node, marked)"]
        vite["Vite\n(bundle)"]
    end

    subgraph Output
        html["src/web-app/docs/*.html\n(generated, not committed)"]
        sitemap["public/sitemap-data.json\n(generated, not committed)"]
        dist["dist/"]
    end

    subgraph Deployment
        ci["GitHub Actions\n(deploy.yml)"]
        tests["GitHub Actions\n(site-tests.yml)"]
        host["GitHub Pages"]
    end

    pages --> builder
    manifest --> builder
    manifest --> vite
    builder --> html
    builder --> sitemap
    html --> vite
    sitemap --> vite
    vite --> dist
    ci -- "on merge to main" --> vite
    dist --> host
    tests -- "on pull request" --> vite
```

---

## Test Inputs

| Test | Reads |
|------|-------|
| `nav.test.mjs` | `docs.manifest.json`, `dist/docs/*.html` |
| `brand-guard.test.mjs` | Every tracked file, `dist/` |
| `capitals.test.mjs` | Pages, `index.html`, `dist/` |
| `links.test.mjs` | `dist/` |
| `style.test.mjs` | Pages |
| `status-labels.test.mjs` | `six-tools.md`, `what-is-ravintio.md` |
| `reference-match.test.mjs` | Reference pages, `ravintio-zero/skills/`, `standards/`, `templates/` |
| `mcp-config.test.mjs` | `.mcp.json` |
| `site-tests-workflow.test.mjs` | `.github/workflows/site-tests.yml` |
| `quality-review.test.mjs` | `ravintio-overrides/capability-skills/site-quality-review/`, `ravintio-overrides/instructions/custom-003-site-quality-review.md` |
| `e2e/*.spec.ts` | `docs.manifest.json`, `dist/` served by `vite preview` |

---

## The installed pack

`ravintio-zero/` is a copy of the RAVINTIO Zero pack. It governs how this repo changes. The site build doesn't read it. Only `reference-match.test.mjs` reads it, to keep the reference pages accurate.
