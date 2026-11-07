// REQ-006: the header and footer code links point to the RAVINTIO organisation.
import { describe, test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { DIST, walk } from './helpers.mjs';

const ORG_URL = 'https://github.com/RAVINTIO';
const LABEL = 'RAVINTIO on GitHub';

const builtPages = () => walk(DIST).filter(f => f.endsWith('.html') && !f.includes(`${path.sep}assets${path.sep}`));
const headerLink = html => html.match(/<a\s[^>]*class="code-icon-link"[^>]*>/)?.[0];
const footerLink = html => html.match(/<div class="footer-links">[\s\S]*?<a\s[^>]*href="([^"]+)"[^>]*>GitHub<\/a>/)?.[1];

describe('req-006-organisation-code-link', () => {
  test('req-006 AC-1: header and footer code links point to the organisation', () => {
    const pages = builtPages();
    assert.ok(pages.length > 1, 'the site is built');
    const wrong = [];
    for (const file of pages) {
      const html = fs.readFileSync(file, 'utf-8');
      const name = path.relative(DIST, file);
      const header = headerLink(html);
      if (!header?.includes(`href="${ORG_URL}"`)) wrong.push(`${name}: header ${header ?? 'missing'}`);
      if (footerLink(html) !== ORG_URL) wrong.push(`${name}: footer ${footerLink(html) ?? 'missing'}`);
    }
    assert.deepEqual(wrong, []);
  });

  test('req-006 AC-2: the header link label names RAVINTIO', () => {
    const wrong = [];
    for (const file of builtPages()) {
      const header = headerLink(fs.readFileSync(file, 'utf-8')) ?? '';
      if (!header.includes(`aria-label="${LABEL}"`) || !header.includes(`title="${LABEL}"`)) {
        wrong.push(path.relative(DIST, file));
      }
    }
    assert.deepEqual(wrong, []);
  });
});
