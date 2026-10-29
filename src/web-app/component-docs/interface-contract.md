# Interface contract - web-app

## Inputs

| Name | Type | Description |
|------|------|-------------|
| `src/site-content/pages/*.md` | filesystem, build time | One Markdown page per manifest entry. Read only. |
| `docs.manifest.json` | filesystem, build time | `{ "sections": [ { "title", "pages": [ { "file", "title" } ] } ] }` |

## Outputs

| Name | Type | Description |
|------|------|-------------|
| `dist/` | filesystem | The built site that GitHub Pages serves |
| `docs/*.html` | filesystem, generated | One HTML page per manifest entry, plus `sitemap.html`. Not committed. |
| `public/sitemap-data.json` | filesystem, generated | Every page with its file, title, and section. Not committed. |

## Consumes

- `site-content`

## Page link contract

- A page links another page as `{slug}.md` or `{slug}.md#{anchor}`. The build rewrites the target to `.html`.
- A heading's anchor is its text in lower case, with other characters than letters, digits, spaces, underscores, and hyphens removed, and spaces turned into hyphens.

## Breaking change policy

`requires-human-approval`. A change to the manifest format or the page link contract needs human review.
