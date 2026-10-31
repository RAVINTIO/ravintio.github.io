import { describe, test } from 'node:test';
import assert from 'node:assert/strict';
import { readBuilt, builtSections } from './helpers.mjs';

describe('req-003-zero-overview-reframe: AC-1 section order', () => {
  test('Why use Zero is first, How a run flows second, and Terms last', () => {
    const titles = builtSections('zero-overview').map(s => s.title);
    assert.equal(titles[0], 'Why use Zero?');
    assert.equal(titles[1], 'How a run flows');
    assert.equal(titles.at(-1), 'Terms');
  });

  test('Why use Zero links back to Why use RAVINTIO', () => {
    const [first] = builtSections('zero-overview');
    assert.match(first.html, /href="what-is-ravintio\.html#why-use-ravintio"/);
  });
});

describe('req-003-zero-overview-reframe: AC-2 When Zero fits', () => {
  test('When Zero fits replaces Limits of Zero, with no benchmark line', () => {
    const titles = builtSections('zero-overview').map(s => s.title);
    assert.ok(titles.includes('When Zero fits'));
    assert.ok(!titles.includes('Limits of Zero'));
    const html = readBuilt('zero-overview');
    assert.doesNotMatch(html, /benchmark/i);
    assert.doesNotMatch(html, /Overhead is real/);
  });
});
