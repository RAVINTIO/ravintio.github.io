import { describe, test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { readManifest, DIST, DIST_DOCS } from './helpers.mjs';
import { escapeHtml, checkDescriptions } from '../scripts/manifest.js';

const pages = readManifest().sections.flatMap(s => s.pages);
const META = /<meta name="description" content="([^"]*)"\s*\/?>/g;

function homeDescription() {
  const home = fs.readFileSync(path.join(DIST, 'index.html'), 'utf-8');
  return home.match(/<meta name="description" content="([^"]*)"/)?.[1] ?? '';
}

describe('req-002-meta-descriptions: AC-1 one description per page', () => {
  for (const page of pages) {
    test(`${page.file} has one meta description that matches the manifest`, () => {
      const head = fs.readFileSync(path.join(DIST_DOCS, page.file), 'utf-8').split('</head>')[0];
      const found = [...head.matchAll(META)].map(m => m[1]);
      assert.equal(found.length, 1, `meta descriptions found: ${found.length}`);
      assert.equal(found[0], escapeHtml(page.description ?? ''));
    });
  }

  test('the build check names a page that has no description', () => {
    const sections = [{ title: 'S', pages: [{ file: 'a.html', title: 'A', description: 'x' }, { file: 'b.html', title: 'B' }] }];
    assert.throws(() => checkDescriptions({ sections }), /b\.html/);
  });
});

describe('req-002-meta-descriptions: AC-2 unique and sized', () => {
  test('every page description is unique and differs from the homepage', () => {
    const all = [homeDescription(), ...pages.map(p => p.description)];
    assert.equal(new Set(all).size, all.length, 'descriptions repeat');
  });

  for (const page of pages) {
    test(`${page.file} description runs 50 to 160 characters`, () => {
      const length = page.description?.length ?? 0;
      assert.ok(length >= 50 && length <= 160, `length ${length}`);
    });
  }
});
