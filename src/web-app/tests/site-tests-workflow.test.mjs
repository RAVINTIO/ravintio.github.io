// REQ-003: site-tests.yml runs both suites on each pull request (ADR-002).
// Node built-ins only, so the checks read the workflow as text.
import { describe, test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { REPO } from './helpers.mjs';

const WORKFLOW = path.join(REPO, '.github/workflows/site-tests.yml');
const read = () => fs.readFileSync(WORKFLOW, 'utf8');

describe('req-003-ci-site-tests', () => {
  test('req-003 AC-1: runs on pull requests into main', () => {
    assert.ok(fs.existsSync(WORKFLOW), 'site-tests.yml is missing');
    const text = read();
    assert.match(text, /^on:\s*\n\s+pull_request:\s*\n\s+branches:\s*\[\s*main\s*\]/m);
    assert.doesNotMatch(text, /^\s+push:/m, 'the workflow runs on pull requests only');
  });

  test('req-003 NFR-004: grants read-only contents permission', () => {
    assert.match(read(), /^permissions:\s*\n\s+contents:\s*read\s*$/m);
  });

  test('req-003 AC-1: installs, builds, and runs both suites in order', () => {
    const text = read();
    const steps = [
      'npm ci',
      'npx playwright install --with-deps chromium',
      'npm run build',
      'npm test',
      'npm run test:e2e',
    ];
    let last = -1;
    for (const step of steps) {
      const at = text.indexOf(`run: ${step}`);
      assert.ok(at > last, `"run: ${step}" is missing or out of order`);
      last = at;
    }
    assert.match(text, /working-directory:\s*src\/web-app/);
  });

  test('req-003 AC-2: uploads the Playwright report when a step fails', () => {
    const text = read();
    const upload = text.slice(text.indexOf('actions/upload-artifact'));
    assert.ok(text.includes('actions/upload-artifact'), 'no upload step');
    assert.match(text, /if:\s*failure\(\)/);
    assert.match(upload, /path:\s*src\/web-app\/playwright-report/);
  });
});

// REQ-005: the site workflows pin every action by full commit SHA (ADR-004).
// ravintio.yml stays as setup.sh writes it, so the checks skip that file.
const PINNED = ['site-tests.yml', 'deploy.yml'].map((name) => ({
  name,
  file: path.join(REPO, '.github/workflows', name),
}));
const PIN = /^[\w.-]+\/[\w.-]+(\/[\w./-]+)?@[0-9a-f]{40} # v\d+$/;

const usesLines = (file) =>
  fs
    .readFileSync(file, 'utf8')
    .split('\n')
    .map((line, i) => ({ n: i + 1, text: line.trim() }))
    .filter(({ text }) => /^(-\s+)?uses:/.test(text));

describe('req-005-pin-actions-by-sha', () => {
  for (const { name, file } of PINNED) {
    test(`req-005 AC-1: ${name} pins each action by SHA with a tag comment`, () => {
      const lines = usesLines(file);
      assert.ok(lines.length > 0, `${name} has no uses: lines`);
      for (const { n, text } of lines) {
        const ref = text.replace(/^(-\s+)?uses:\s*/, '');
        assert.match(ref, PIN, `${name}:${n} is not pinned by SHA with a # v<n> comment: ${text}`);
      }
    });
  }

  test('req-005 AC-2: the failure message names the offending line', () => {
    const bad = 'actions/checkout@v5';
    assert.throws(
      () => assert.match(bad, PIN, `site-tests.yml:20 is not pinned: uses: ${bad}`),
      /site-tests\.yml:20 .*actions\/checkout@v5/,
    );
  });
});
