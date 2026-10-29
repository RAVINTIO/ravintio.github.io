import { describe, test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { REPO, DIST, trackedFiles, walk } from './helpers.mjs';

// Built from two parts so this file holds no match of its own (ADR-004).
const EARLIER = new RegExp('plani' + 'fest', 'i');

const ALLOW = [
  'plan/_archive/',
  'plan/changelog/',
  'ravintio-zero/',
  'src/web-app/tests/brand-guard.test.mjs',
];

const allowed = rel => ALLOW.some(a => rel === a || rel.startsWith(a));

function scan(files) {
  const hits = [];
  for (const rel of files) {
    if (allowed(rel)) continue;
    if (EARLIER.test(rel)) { hits.push(`${rel} (path)`); continue; }
    const abs = path.join(REPO, rel);
    if (!fs.existsSync(abs) || fs.statSync(abs).isDirectory()) continue;
    const buf = fs.readFileSync(abs);
    if (buf.includes(0)) continue; // binary
    if (EARLIER.test(buf.toString('utf-8'))) hits.push(rel);
  }
  return hits;
}

describe('req-004-brand-and-structure: AC-2 no earlier-brand text', () => {
  test('no tracked file outside the allowlist names the earlier brand', () => {
    assert.deepEqual(scan(trackedFiles()), []);
  });

  test('no built file in dist names the earlier brand', () => {
    const files = walk(DIST).map(f => path.relative(REPO, f));
    assert.ok(files.length > 0, 'dist is built');
    assert.deepEqual(scan(files), []);
  });
});
