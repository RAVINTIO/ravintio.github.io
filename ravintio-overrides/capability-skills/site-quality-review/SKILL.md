---
name: site-quality-review
description: Reviews the built site through Playwright MCP for accessibility, layout, content, performance, and navigation. Fixes urgent findings in the run, files the rest to plan/backlog/, and writes plan/current/site-quality-report.md. Runs in P3 after the Playwright suite passes.
---

# Site quality review

You review the site in P3, after the Playwright suite passes. You write `plan/current/site-quality-report.md`, fix urgent findings in the run, and file the rest to the backlog.

## Procedure

1. Check the preconditions.
   - The Playwright suite (`npm run test:e2e`) passed in this run.
   - Playwright MCP tools are available, such as `browser_navigate`, `browser_snapshot`, `browser_resize`, `browser_take_screenshot`, `browser_evaluate`, and `browser_console_messages`.
   - If the tools are missing, stop with `P3 Validate: Blocked: Playwright MCP is not available, so the site quality review cannot run.` Never skip the review.
2. Mark progress in `plan/current/build-log.md` with `- In progress: site quality review ({timestamp})`. Add `- Done:` at the end. A rerun continues from the report on disk.
3. Build and serve the site.
   - Run `cd src/web-app && npm run build`.
   - Start `npx vite preview --port 4173 --strictPort` in the background.
   - Navigate only to `http://localhost:4173`. Never open an external URL in the MCP browser.
4. Review the homepage and each page in `src/web-app/docs.manifest.json`.
5. Review the five areas.
   - **Accessibility, WCAG 2.2 AA.** Read the accessibility tree with `browser_snapshot`. Check heading order, names on controls, link text, and alt text. Press Tab with `browser_press_key` to check focus order. Check colour contrast with `browser_evaluate` on computed colours.
   - **Layout, 390 px and 1280 px, in both themes.** Resize with `browser_resize`. Set `localStorage['ravintio-theme']` and reload to switch themes. Take screenshots and look for overlap, clipping, and uneven spacing.
   - **Content, writing style and pack facts.** Read each page's Markdown in `src/site-content/pages/` against the repo's writing style. Check the reference pages against the installed pack in `ravintio-zero/` for stale facts.
   - **Performance, under 500 KB and LCP under 2.5 s.** Sum `transferSize` over the navigation and resource entries. Read the largest contentful paint with a `PerformanceObserver` that sets `buffered: true`.
   - **Navigation and metadata.** Check for a unique `<title>` and a meta description on each page, a working 404 page, and a favicon that loads.
6. Sort each finding. A finding is fix-now when any of these is true. Every other finding is a backlog finding.
   - The current run caused it.
   - It fails WCAG 2.2 level A.
   - A link or anchor is broken, or a page logs a console error.
   - A page breaks at 390 px with overlap, clipping, or horizontal scroll.
7. Size the fix-now work with the S, M, and L points (S 1, M 2, L 4). If the total passes 2 points, stop and ask the human which findings to fix now. Run the fix-now work as P3 self-correct units under the owning component's rules.
8. File each backlog finding.
   - Search `plan/backlog/*/entry.md` for an entry on the same page and issue.
   - If one exists, append the new evidence under a dated heading and file nothing new.
   - Otherwise reserve an id with `node ravintio-zero/scripts/reserve-id.mjs`. Write `plan/backlog/{id}-{slug}/entry.md` from `ravintio-zero/templates/backlog-entry.template.md`.
   - Set the source phase to P3 and the deferral source to `discovered mid-flight`. Include the page, area, evidence, and a suggested fix.
9. Write `plan/current/site-quality-report.md` from `ravintio-overrides/capability-skills/site-quality-review/report.template.md`. Setup installs only `SKILL.md`, so read the template from that source path. Add each finding to the file as you find it. Stop the preview server at the end.
