#!/usr/bin/env node
/**
 * release-tag.mjs - tag HEAD with the product version and push the tag.
 *
 * Usage: node release-tag.mjs [--root <projectRoot>]
 *
 * Reads `version:` and `feature:` from product.yml. If product.yml has no
 * version, reads them from the docs/about.md frontmatter. ADR-002 (feature
 * 0000169) has CI run this script on the merge commit on main.
 *
 * Exit codes:
 *   0 - tag created and pushed, or the tag already exists (skipped)
 *   1 - no version, invalid version, tag failure, or push failure
 *
 * No YAML dependency. Node.js built-ins only (ADR-001).
 */

import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { spawnSync } from "node:child_process";

const VERSION_RE = /^[0-9]+\.[0-9]+(\.[0-9]+)?$/;

function fail(msg) {
  process.stderr.write(`release-tag: ${msg}\n`);
  process.exit(1);
}

function unquote(v) {
  return v.trim().replace(/^["']|["']$/g, "");
}

// Read top-level `key: value` scalars. For a frontmatter file, read only
// the block between the first two `---` lines.
function readScalars(path, frontmatter) {
  const out = {};
  if (!existsSync(path)) return out;
  let lines = readFileSync(path, "utf-8").split(/\r?\n/);
  if (frontmatter) {
    if (lines[0] !== "---") return out;
    const end = lines.indexOf("---", 1);
    lines = lines.slice(1, end < 0 ? lines.length : end);
  }
  for (const raw of lines) {
    const m = raw.replace(/\s#.*$/, "").trimEnd().match(/^(version|feature):\s*(.+)$/);
    if (m) out[m[1]] = unquote(m[2]);
  }
  return out;
}

function git(args, cwd) {
  const r = spawnSync("git", args, { cwd, encoding: "utf-8" });
  return { ok: r.status === 0, out: (r.stdout || "").trim(), err: (r.stderr || "").trim() };
}

const i = process.argv.indexOf("--root");
const root = i >= 0 && process.argv[i + 1] ? process.argv[i + 1] : process.cwd();

const product = readScalars(join(root, "product.yml"), false);
const about = readScalars(join(root, "docs", "about.md"), true);
const version = product.version || about.version;
if (!version) fail("no version found in product.yml or docs/about.md");
if (!VERSION_RE.test(version)) fail(`invalid version ${JSON.stringify(version)} (expected MAJOR.MINOR or MAJOR.MINOR.PATCH)`);

const tag = `v${version}`;
const ref = `refs/tags/${tag}`;
const message = product.feature || about.feature || tag;

const local = git(["rev-parse", "--verify", "--quiet", ref], root);
const remote = git(["ls-remote", "--tags", "origin", ref], root);
if (local.ok || (remote.ok && remote.out)) {
  process.stdout.write(`release-tag: ${tag} exists, skipped\n`);
  process.exit(0);
}

const created = git(["tag", "-a", tag, "-m", message, "HEAD"], root);
if (!created.ok) fail(`could not create ${tag}: ${created.err}`);

const pushed = git(["push", "origin", ref], root);
if (!pushed.ok) fail(`push of ${tag} to origin failed: ${pushed.err}`);

process.stdout.write(`release-tag: ${tag} created and pushed\n`);
