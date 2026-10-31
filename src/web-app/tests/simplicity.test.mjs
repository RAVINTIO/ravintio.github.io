import { describe, test } from 'node:test';
import assert from 'node:assert/strict';
import { readBuilt, builtSections, boldLeads } from './helpers.mjs';

describe('req-002-simplicity-guidance: AC-1 zero overview simplicity section', () => {
  test('How Zero keeps solutions simple covers discovery, plan, implement, and standards', () => {
    const s = builtSections('zero-overview').find(x => x.title === 'How Zero keeps solutions simple');
    assert.ok(s, 'section exists');
    assert.deepEqual(boldLeads(s.html), ['Discovery', 'Plan', 'Implement', 'Standards']);
  });
});

describe('req-002-simplicity-guidance: AC-2 pipeline P2 simplicity sentence', () => {
  test('the P2 section asks whether a simpler solution meets the same tests', () => {
    const p2 = readBuilt('pipeline').match(/<h3 id="p2-implement">[\s\S]*?(?=<h[23] )/);
    assert.ok(p2, 'P2 section exists');
    assert.match(p2[0], /Each cycle asks whether a simpler solution meets the same tests\./);
  });
});
