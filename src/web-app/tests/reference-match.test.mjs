import { describe, test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { PACK, readPage } from './helpers.mjs';

// Pack items per reference page (ADR-005).
const SOURCES = {
  skills: () => fs.readdirSync(path.join(PACK, 'skills'), { withFileTypes: true })
    .filter(e => e.isDirectory()).map(e => e.name),
  standards: () => fs.readdirSync(path.join(PACK, 'standards'), { withFileTypes: true })
    .filter(e => e.isFile() && e.name.endsWith('.md')).map(e => e.name),
  templates: () => fs.readdirSync(path.join(PACK, 'templates'), { withFileTypes: true })
    .filter(e => e.isFile()).map(e => e.name),
};

// Items are written as "### `name`" headings.
const documented = slug => [...readPage(slug).matchAll(/^### `([^`]+)`\s*$/gm)].map(m => m[1]);

describe('req-003-zero-reference: AC-2 every pack item is documented', () => {
  for (const slug of Object.keys(SOURCES)) {
    test(`${slug} page lists every item in the pack folder`, () => {
      const missing = SOURCES[slug]().filter(item => !documented(slug).includes(item));
      assert.deepEqual(missing, []);
    });
  }
});

describe('req-003-zero-reference: AC-3 no item outside the pack is documented', () => {
  for (const slug of Object.keys(SOURCES)) {
    test(`${slug} page names only items that exist in the pack`, () => {
      const pack = SOURCES[slug]();
      const extra = documented(slug).filter(item => !pack.includes(item));
      assert.deepEqual(extra, []);
    });
  }
});
