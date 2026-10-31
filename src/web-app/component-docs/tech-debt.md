# Tech debt - web-app

## TD-002: Fixed nav height in `scroll-margin-top`

`scroll-margin-top: 72px` matches the nav height. If the nav height changes, anchor scrolling lands in the wrong place. A `--nav-height` custom property would remove the fixed value.

## TD-003: HTML checks use regular expressions

The link and nav tests read built HTML with regular expressions, not a DOM parser. They rely on the markup that `build-docs.js` writes. See ADR-001 of feature 0000005.
