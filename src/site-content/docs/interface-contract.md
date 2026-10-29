# Interface contract - site-content

## Outputs

| Name | Type | Description |
|------|------|-------------|
| `pages/{slug}.md` | filesystem | One page per entry in `src/web-app/docs.manifest.json` |

## Page rules

- Each page starts with one `#` heading that matches its manifest title.
- Links to other pages use `{slug}.md` or `{slug}.md#{anchor}`.
- `six-tools.md` gives each tool a `## RAVINTIO {Name}` heading followed by a `**Status:** {label}` line.
- Reference pages name each pack item in a ``### `name` `` heading.

## Consumed by

- `web-app`, at build time and test time. It reads the pages and never writes them.

## Breaking change policy

`requires-adr`. A change to the page rules above needs an ADR, because the build and tests depend on them.
