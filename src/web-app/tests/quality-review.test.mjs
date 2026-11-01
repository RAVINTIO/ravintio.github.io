// REQ-005: the site quality review skill, its template, and its repo instruction.
import { describe, test } from 'node:test';
import assert from 'node:assert';
import fs from 'node:fs';
import path from 'node:path';
import { REPO } from './helpers.mjs';

const read = (rel) => fs.readFileSync(path.join(REPO, rel), 'utf-8');
const SKILL_DIR = 'ravintio-overrides/capability-skills/site-quality-review';
const norm = (s) => s.replace(/\s+/g, ' ');

describe('req-005 repo instruction', () => {
  const file = 'ravintio-overrides/instructions/custom-003-site-quality-review.md';

  test('req-005 the instruction exists and names the skill', () => {
    assert.ok(fs.existsSync(path.join(REPO, file)), `${file} is missing`);
    assert.match(read(file), /site-quality-review/);
  });

  test('req-005 the instruction runs in P3 after the Playwright suite passes', () => {
    const text = norm(read(file));
    assert.match(text, /\bP3\b/);
    assert.match(text, /after the Playwright suite passes/i);
  });
});

describe('req-005 skill', () => {
  const skill = () => norm(read(`${SKILL_DIR}/SKILL.md`));

  test('req-005 frontmatter has name and description', () => {
    const fm = read(`${SKILL_DIR}/SKILL.md`).match(/^---\n([\s\S]*?)\n---/);
    assert.ok(fm, 'no frontmatter');
    assert.match(fm[1], /^name: site-quality-review$/m);
    assert.match(fm[1], /^description: .+/m);
  });

  test('req-005 names the five areas and their targets', () => {
    const text = skill();
    for (const phrase of [
      'WCAG 2.2 AA', '390 px', '1280 px', 'both themes', 'writing style',
      'pack facts', '500 KB', '2.5 s', '<title>', 'meta description', '404', 'favicon',
    ]) {
      assert.ok(text.includes(phrase), `missing: ${phrase}`);
    }
  });

  test('req-005 states the four fix-now conditions', () => {
    const text = skill();
    assert.match(text, /current run caused/i);
    assert.match(text, /WCAG 2\.2 level A/);
    assert.match(text, /broken/i);
    assert.match(text, /console error/i);
    assert.match(text, /breaks at 390 px/i);
  });

  test('req-005 states the cap, duplicate check, blocked stop, output, and origin', () => {
    const text = skill();
    assert.match(text, /2 points/);
    assert.match(text, /ask the human/i);
    assert.match(text, /same page and issue/i);
    assert.match(text, /append the new evidence/i);
    assert.match(text, /Blocked: Playwright MCP is not available/);
    assert.ok(text.includes('plan/current/site-quality-report.md'));
    assert.ok(text.includes('http://localhost:4173'));
  });
});

describe('req-005 report template', () => {
  test('req-005 has one section per area', () => {
    const text = read(`${SKILL_DIR}/report.template.md`);
    for (const area of ['Accessibility', 'Layout', 'Content', 'Performance', 'Navigation and metadata']) {
      assert.match(text, new RegExp(`^## ${area}$`, 'm'), `missing section: ${area}`);
    }
  });
});
