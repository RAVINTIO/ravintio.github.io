import { describe, test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { EXPECTED_SECTIONS, readBuilt, WEB_APP } from './helpers.mjs';

const pages = EXPECTED_SECTIONS.flatMap(s => s.pages);
const css = fs.readFileSync(path.join(WEB_APP, 'src/style.css'), 'utf-8');
const mainTs = fs.readFileSync(path.join(WEB_APP, 'src/main.ts'), 'utf-8');

describe('req-005-mobile-section-nav: AC-3 nav sits in a disclosure', () => {
  test('every built page wraps the page list in an open details element', () => {
    for (const [slug] of pages) {
      const html = readBuilt(slug);
      assert.match(html,
        /<details class="doc-sections__disclosure" open>\s*<summary[^>]*>[\s\S]*?<\/summary>\s*<nav class="doc-sections"[\s\S]*?<\/nav>\s*<\/details>/,
        slug);
    }
  });

  test('desktop CSS hides only the summary', () => {
    assert.match(css, /@media \(min-width: 901px\)\s*\{[^}]*\.doc-sections__summary\s*\{\s*display:\s*none/);
  });
});

describe('req-005-mobile-section-nav: AC-1 closed on a phone, naming the current page', () => {
  test('the summary names the current page', () => {
    for (const [slug, title] of pages) {
      const summary = readBuilt(slug).match(/<summary[^>]*>([\s\S]*?)<\/summary>/);
      assert.ok(summary, slug);
      assert.match(summary[1], new RegExp(title), slug);
    }
  });

  test('main.ts closes the disclosure at the mobile breakpoint and reopens it on desktop', () => {
    assert.match(mainTs, /matchMedia\('\(max-width: 900px\)'\)/);
    assert.match(mainTs, /\.doc-sections__disclosure/);
    assert.match(mainTs, /addEventListener\('change'/);
  });
});
