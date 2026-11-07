import { describe, test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { readBuilt, readPage, builtSections, DIST } from './helpers.mjs';

const TOOLS = ['Zero', 'Framework', 'Accept', 'Qualify', 'Insight', 'Unbound'];
const NAMES_A_TOOL = new RegExp(`\\b(${TOOLS.join('|')})\\b`);

// The first paragraph after the H1 of a built page.
function openingParagraph(slug) {
  const html = readBuilt(slug);
  const afterH1 = html.slice(html.indexOf('</h1>'));
  return afterH1.match(/<p>([\s\S]*?)<\/p>/)?.[1] ?? '';
}

// The H3 entries of the "The six tools" section in the Markdown source: [{ title, words }].
function toolEntries() {
  const section = readPage('what-is-ravintio').split(/^## /m).find(s => s.startsWith('The six tools\n'));
  assert.ok(section, 'the six tools section exists');
  return section.split(/^### /m).slice(1).map(part => {
    const [title, ...body] = part.split('\n');
    return { title: title.trim(), words: body.join(' ').split(/\s+/).filter(Boolean).length };
  });
}

describe('req-001-explainer-six-tools: AC-1 purpose first, and the why names no tool', () => {
  test('the opening paragraph names visibility and governance over agentic software development', () => {
    const p = openingParagraph('what-is-ravintio');
    assert.match(p, /visibility/);
    assert.match(p, /governance/);
    assert.match(p, /agentic software development/);
  });

  test('the first H2 is Why RAVINTIO? and names none of the six tools', () => {
    const [first] = builtSections('what-is-ravintio');
    assert.equal(first.title, 'Why RAVINTIO?');
    assert.doesNotMatch(first.html.replace(/<[^>]+>/g, ' '), NAMES_A_TOOL);
  });
});

describe('req-001-explainer-six-tools: AC-2 balanced tool entries', () => {
  test('The six tools holds one H3 entry per tool in order', () => {
    assert.deepEqual(toolEntries().map(e => e.title), TOOLS.map(t => `RAVINTIO ${t}`));
  });

  test('the longest entry has at most 1.5 times the words of the shortest', () => {
    const counts = toolEntries().map(e => e.words);
    assert.equal(counts.length, 6);
    assert.ok(Math.max(...counts) <= 1.5 * Math.min(...counts), `word counts: ${counts.join(', ')}`);
  });
});

describe('req-001-explainer-six-tools: AC-3 purpose-led subtitle', () => {
  test('the hero subtitle names the shared purpose and no tool', () => {
    const home = fs.readFileSync(path.join(DIST, 'index.html'), 'utf-8');
    const subtitle = home.match(/<p class="subtitle[^"]*">\s*([\s\S]*?)\s*<\/p>/)?.[1] ?? '';
    assert.match(subtitle, /visibility/);
    assert.match(subtitle, /governance/);
    assert.match(subtitle, /agentic/);
    assert.doesNotMatch(subtitle, NAMES_A_TOOL);
  });

  test('the homepage meta description names the shared purpose and no tool', () => {
    const home = fs.readFileSync(path.join(DIST, 'index.html'), 'utf-8');
    const meta = home.match(/<meta name="description" content="([^"]*)"/)?.[1] ?? '';
    assert.match(meta, /visibility and governance over agentic software development/);
    assert.doesNotMatch(meta, NAMES_A_TOOL);
  });
});
