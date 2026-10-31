import { describe, test } from 'node:test';
import assert from 'node:assert/strict';
import { readBuilt, readPage, builtSections, boldLeads } from './helpers.mjs';

const AGREED_LEADS = [
  'Changes are designed before they&#39;re built.',
  'Work follows your standards.',
  'Documentation comes with the code.',
  'Architectural decisions are on record.',
  'Constraints hold.',
  'Solutions stay as simple as the problem allows.',
  'Done means proven.',
  'Failures get fixed, not reported.',
  'Work survives a new session.',
  'No lock-in.',
];

describe('req-001-why-use-ravintio: AC-1 Why use RAVINTIO holds the agreed list', () => {
  test('the first H2 is Why use RAVINTIO with the ten agreed leads in order', () => {
    const [first] = builtSections('what-is-ravintio');
    assert.equal(first.title, 'Why use RAVINTIO');
    assert.deepEqual(boldLeads(first.html), AGREED_LEADS);
  });

  test('the page has no name section, letter table, or block-capitals sentence', () => {
    const titles = builtSections('what-is-ravintio').map(s => s.title);
    assert.ok(!titles.includes('The name'));
    const html = readBuilt('what-is-ravintio');
    assert.doesNotMatch(html, /<th>Letter<\/th>/);
    assert.doesNotMatch(html, /block capitals/i);
  });

  test('six-tools points to what-is-ravintio for why to use RAVINTIO', () => {
    const intro = readPage('six-tools').split('\n')[2];
    assert.doesNotMatch(intro, /the name/i);
    assert.match(intro, /why to use RAVINTIO/);
    assert.match(intro, /\(what-is-ravintio\.md\)/);
  });
});

describe('req-001-why-use-ravintio: AC-2 principles trimmed', () => {
  test('Shared design principles holds exactly the three kept bullets', () => {
    const s = builtSections('what-is-ravintio').find(x => x.title === 'Shared design principles');
    assert.ok(s, 'section exists');
    assert.deepEqual(boldLeads(s.html), [
      'Humans keep authority over consequential decisions.',
      'Assessment challenges the work.',
      'Learning is blameless.',
    ]);
  });
});
