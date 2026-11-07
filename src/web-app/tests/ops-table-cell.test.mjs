import { describe, test } from 'node:test';
import assert from 'node:assert/strict';
import { readPage } from './helpers.mjs';

const ROW_START = '| `.github/workflows/ravintio.yml` |';

describe('req-007: AC-1 the ravintio.yml table cell names the actor', () => {
  test('req-007 the cell reads "The CI gate works only after you commit it." and the old wording is gone', () => {
    const md = readPage('project-operations');
    const rows = md.split('\n').filter(line => line.startsWith(ROW_START));
    assert.equal(rows.length, 1, 'one ravintio.yml row exists');
    const cells = rows[0].split('|').map(c => c.trim()).filter(Boolean);
    assert.equal(cells[2], 'The CI gate works only after you commit it.');
    assert.ok(!md.includes('only works once committed'), 'the old wording is gone');
  });
});
