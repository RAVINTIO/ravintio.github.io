import { describe, test } from 'node:test';
import assert from 'node:assert/strict';
import { readBuilt, readPage, builtSections, boldLeads } from './helpers.mjs';

const AGREED_LEADS = [
  'You see what the agent did.',
  'You see why.',
  'You decide what ships.',
  'Evidence backs every claim.',
  'You keep your own tools.',
];

describe('req-001-why-use-ravintio: AC-1 Why RAVINTIO? holds the shared purpose', () => {
  test('the first H2 is Why RAVINTIO? with the agreed leads in order', () => {
    const [first] = builtSections('what-is-ravintio');
    assert.equal(first.title, 'Why RAVINTIO?');
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
