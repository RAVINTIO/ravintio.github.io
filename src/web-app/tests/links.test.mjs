import { describe, test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { DIST, DIST_DOCS, walk } from './helpers.mjs';

const ids = html => new Set([...html.matchAll(/\sid="([^"]+)"/g)].map(m => m[1]));

describe('req-002-zero-adoption-guide: AC-2 every internal link resolves', () => {
  test('every internal href and anchor in the built site resolves', () => {
    const pages = walk(DIST).filter(f => f.endsWith('.html'));
    assert.ok(pages.some(f => f.startsWith(DIST_DOCS)), 'docs are built');
    const broken = [];
    for (const file of pages) {
      const html = fs.readFileSync(file, 'utf-8');
      for (const [, href] of html.matchAll(/<a\s[^>]*href="([^"]+)"/g)) {
        if (/^(https?:|mailto:)/.test(href)) continue;
        const [target, anchor] = href.split('#');
        const targetFile = target ? path.resolve(path.dirname(file), target) : file;
        if (!fs.existsSync(targetFile)) { broken.push(`${path.relative(DIST, file)} -> ${href}`); continue; }
        if (anchor && !ids(fs.readFileSync(targetFile, 'utf-8')).has(anchor)) {
          broken.push(`${path.relative(DIST, file)} -> ${href} (anchor)`);
        }
      }
    }
    assert.deepEqual(broken, []);
  });
});
