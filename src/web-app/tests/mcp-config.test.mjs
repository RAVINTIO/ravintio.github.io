// REQ-004: the repo declares Playwright MCP at an exact version (ADR-003).
import { describe, test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { REPO } from './helpers.mjs';

const MCP_FILE = path.join(REPO, '.mcp.json');
const PINNED = '@playwright/mcp@0.0.83';

describe('req-004-playwright-mcp-config', () => {
  test('req-004 AC-1: .mcp.json declares a playwright server pinned at 0.0.83', () => {
    assert.ok(fs.existsSync(MCP_FILE), '.mcp.json is missing at the repo root');
    const config = JSON.parse(fs.readFileSync(MCP_FILE, 'utf8'));
    const server = config.mcpServers?.playwright;
    assert.ok(server, 'no "playwright" server in mcpServers');
    assert.equal(server.command, 'npx');
    const pkgArgs = server.args.filter(a => a.startsWith('@playwright/mcp'));
    assert.deepEqual(pkgArgs, [PINNED], `expected exactly ${PINNED}`);
  });

  test('req-004 AC-1: no version range or latest tag', () => {
    const text = fs.readFileSync(MCP_FILE, 'utf8');
    assert.doesNotMatch(text, /@latest|@\^|@~|@\*/);
  });
});
