import { describe, test } from 'node:test';
import assert from 'node:assert/strict';
import { readPage, stripCode } from './helpers.mjs';

// Confirmed status labels (design.md constraints).
const LABELS = {
  'RAVINTIO Zero': 'Available',
  'RAVINTIO Framework': 'Available',
  'RAVINTIO Accept': 'In design',
  'RAVINTIO Qualify': 'In design',
  'RAVINTIO Insight': 'In design',
  'RAVINTIO Unbound': 'In design, experimental research only',
};

// Each tool is a "## RAVINTIO {Name}" section holding one "**Status:** {label}" line.
function statusByTool(markdown) {
  const out = {};
  const parts = markdown.split(/^## /m).slice(1);
  for (const part of parts) {
    const name = part.split('\n')[0].trim();
    const labels = [...part.matchAll(/^\*\*Status:\*\* (.+)$/gm)].map(m => m[1].trim());
    out[name] = labels;
  }
  return out;
}

describe('req-001-ravintio-overview: AC-2 every tool carries its status label', () => {
  test('each of the six tools shows exactly its confirmed status label', () => {
    const found = statusByTool(readPage('six-tools'));
    for (const [tool, label] of Object.entries(LABELS)) {
      assert.deepEqual(found[tool], [label], tool);
    }
  });
});

describe('req-001-ravintio-overview: AC-3 no dated or promised work', () => {
  test('pages 1 and 2 hold no coming-soon wording, roadmap, or dates', () => {
    for (const slug of ['what-is-ravintio', 'six-tools']) {
      const text = stripCode(readPage(slug));
      assert.doesNotMatch(text, /coming soon|roadmap|\bplanned for\b|\b20\d\d\b|\bQ[1-4]\b/i, slug);
    }
  });
});
