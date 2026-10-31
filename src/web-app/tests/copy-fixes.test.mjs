import { describe, test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { execFileSync } from 'node:child_process';
import { readPage, readBuilt, builtSections, DIST } from './helpers.mjs';

function stepTwoCommands() {
  const md = readPage('first-run');
  const step = md.slice(md.indexOf('## 2.'), md.indexOf('## 3.'));
  const block = step.match(/```bash\n([\s\S]*?)```/);
  assert.ok(block, 'step 2 has a bash block');
  return block[1];
}

describe('req-004-copy-fixes: AC-1 first-run step 2 succeeds on a fresh setup', () => {
  test('the step 2 commands exit 0 and create the feature brief', () => {
    const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'first-run-'));
    try {
      fs.mkdirSync(path.join(dir, 'ravintio-zero/templates'), { recursive: true });
      fs.writeFileSync(path.join(dir, 'ravintio-zero/templates/feature-brief.template.md'), '# Brief\n');
      fs.mkdirSync(path.join(dir, 'plan'));
      execFileSync('bash', ['-ec', stepTwoCommands()], { cwd: dir, stdio: 'pipe' });
      assert.ok(fs.existsSync(path.join(dir, 'plan/current/feature-brief.md')));
    } finally {
      fs.rmSync(dir, { recursive: true, force: true });
    }
  });
});

describe('req-004-copy-fixes: AC-2 review findings 5 to 8 applied', () => {
  test('install-zero drops the no-minimum-version sentence', () => {
    assert.doesNotMatch(readBuilt('install-zero'), /no minimum version/i);
  });

  test('first-run What you have now names the reviewer and the next session', () => {
    const s = builtSections('first-run').find(x => x.title === 'What you have now');
    assert.ok(s, 'section exists');
    assert.match(s.html, /reviewer/i);
    assert.match(s.html, /next session/i);
  });

  test('six-tools uses What it does and What it works alongside only', () => {
    const html = readBuilt('six-tools');
    assert.doesNotMatch(html, /What it owns|What it doesn&#39;t replace|What it doesn't replace/);
    assert.equal((html.match(/>What it does</g) ?? []).length, 6);
    assert.equal((html.match(/>What it works alongside</g) ?? []).length, 6);
  });

  test('the hero subtitle matches the agreed text', () => {
    const home = fs.readFileSync(path.join(DIST, 'index.html'), 'utf-8');
    const subtitle = home.match(/<p class="subtitle[^"]*">\s*([\s\S]*?)\s*<\/p>/);
    assert.equal(subtitle?.[1], 'Coding agents that build to your design and standards, and prove the result.');
  });
});
