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
