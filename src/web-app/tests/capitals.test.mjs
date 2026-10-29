import { describe, test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { PAGES_DIR, WEB_APP, DIST, walk, stripCode } from './helpers.mjs';

// Any casing of the brand other than block capitals.
const WRONG = /\b(?!RAVINTIO\b)[Rr][Aa][Vv][Ii][Nn][Tt][Ii][Oo]\b/g;

function stripHtml(html) {
  return stripCode(html)
    .replace(/<(script|style|code|pre)[\s\S]*?<\/\1>/g, ' ')
    .replace(/<[^>]+>/g, ' ');
}

function hits(text, label) {
  return [...text.matchAll(WRONG)].map(m => `${label}: ${m[0]}`);
}

describe('req-004-brand-and-structure: AC-3 brand in block capitals', () => {
  test('pages use RAVINTIO in block capitals outside code and URLs', () => {
    const files = walk(PAGES_DIR).filter(f => f.endsWith('.md'));
    assert.ok(files.length > 0, 'pages exist');
    const found = files.flatMap(f => hits(stripCode(fs.readFileSync(f, 'utf-8')), path.basename(f)));
    assert.deepEqual(found, []);
  });

  test('homepage and built HTML use RAVINTIO in block capitals in visible text', () => {
    const html = [path.join(WEB_APP, 'index.html'), ...walk(DIST).filter(f => f.endsWith('.html'))];
    const found = html.flatMap(f => hits(stripHtml(fs.readFileSync(f, 'utf-8')), path.basename(f)));
    assert.deepEqual(found, []);
  });
});
