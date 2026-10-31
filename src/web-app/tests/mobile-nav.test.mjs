import { describe, test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { EXPECTED_SECTIONS, readBuilt, WEB_APP } from './helpers.mjs';
import { syncPageList, MOBILE_QUERY } from '../src/page-list.ts';

const pages = EXPECTED_SECTIONS.flatMap(s => s.pages);
const css = fs.readFileSync(path.join(WEB_APP, 'src/style.css'), 'utf-8');
const escapeHtml = s => s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
  .replace(/"/g, '&quot;').replace(/'/g, '&#39;');

function fakeQuery(matches) {
  const listeners = [];
  return {
    matches,
    addEventListener: (_type, fn) => listeners.push(fn),
    change(next) { this.matches = next; listeners.forEach(fn => fn()); },
  };
}

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
      assert.ok(summary[1].includes(escapeHtml(title)), slug);
    }
  });

  test('the page list closes at 900 px and below, opens above, and follows resizes', () => {
    assert.equal(MOBILE_QUERY, '(max-width: 900px)');
    const phone = { open: true };
    const phoneQuery = fakeQuery(true);
    syncPageList(phone, phoneQuery);
    assert.equal(phone.open, false);
    phoneQuery.change(false);
    assert.equal(phone.open, true);

    const desktop = { open: true };
    const desktopQuery = fakeQuery(false);
    syncPageList(desktop, desktopQuery);
    assert.equal(desktop.open, true);
    desktopQuery.change(true);
    assert.equal(desktop.open, false);
  });
});
