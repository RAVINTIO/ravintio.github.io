import { describe, test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import { EXPECTED_SECTIONS, readManifest, readBuilt, DIST_DOCS } from './helpers.mjs';

const flat = EXPECTED_SECTIONS.flatMap(s => s.pages.map(([slug]) => slug));

function navOrder(html) {
  const nav = html.match(/<nav class="doc-sections"[\s\S]*?<\/nav>/);
  assert.ok(nav, 'built page has a doc-sections nav');
  const sections = [...nav[0].matchAll(/<p class="doc-sections__title">([^<]+)<\/p>/g)].map(m => m[1]);
  const links = [...nav[0].matchAll(/href="([a-z-]+)\.html"/g)].map(m => m[1]);
  return { sections, links };
}

describe('req-004-brand-and-structure: sectioned nav', () => {
  test('manifest groups the ten pages into three sections in the confirmed order', () => {
    const manifest = readManifest();
    const actual = manifest.sections.map(s => ({
      title: s.title,
      pages: s.pages.map(p => [p.file.replace('.html', ''), p.title]),
    }));
    assert.deepEqual(actual, EXPECTED_SECTIONS);
  });

  test('every built page shows the three labelled sections with all ten pages in order', () => {
    for (const slug of flat) {
      assert.ok(fs.existsSync(`${DIST_DOCS}/${slug}.html`), `${slug}.html is built`);
      const { sections, links } = navOrder(readBuilt(slug));
      assert.deepEqual(sections, ['RAVINTIO', 'Zero', 'Reference'], slug);
      assert.deepEqual(links, flat, slug);
    }
  });
});

describe('req-001-ravintio-overview: AC-1 overview pages in the RAVINTIO section', () => {
  test('RAVINTIO section lists What is RAVINTIO then The six tools', () => {
    const s = readManifest().sections.find(x => x.title === 'RAVINTIO');
    assert.deepEqual(s.pages.map(p => p.title), ['What is RAVINTIO?', 'The six tools']);
  });
});

describe('req-002-zero-adoption-guide: AC-1 Zero pages in order', () => {
  test('Zero section lists pages 3 to 7 in the confirmed order', () => {
    const s = readManifest().sections.find(x => x.title === 'Zero');
    assert.deepEqual(s.pages.map(p => p.title),
      ['Zero overview', 'Install Zero', 'Your first run', 'The pipeline', 'Project operations']);
  });
});

describe('req-003-zero-reference: AC-1 reference pages in order', () => {
  test('Reference section lists Skills, Standards, and Templates', () => {
    const s = readManifest().sections.find(x => x.title === 'Reference');
    assert.deepEqual(s.pages.map(p => p.title), ['Skills', 'Standards', 'Templates']);
  });
});
