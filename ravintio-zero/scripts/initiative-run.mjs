#!/usr/bin/env node
// initiative-run.mjs - runs each initiative step in a fresh claude -p session (0000043 ADR-004).
//
// Usage, run from the repository root:
//
//   node ravintio-zero/scripts/initiative-run.mjs [--root <dir>]
//
// Arguments:
//   --root   The working tree that holds plan/. Defaults to the current directory.
//
// Environment:
//   CLAUDE_BIN   The claude executable. Defaults to "claude", found through PATH.
//   RAVINTIO_INITIATIVE_MODEL
//                The model for every step, passed as --model. Defaults to "sonnet".
//                It must match ^[A-Za-z0-9][A-Za-z0-9._:\[\]-]{0,63}$.
//   RAVINTIO_INITIATIVE_MAX_TURNS
//                A turn cap for every step, passed as --max-turns. If unset or empty,
//                no cap applies and no default ships. It must be 1 to 9999. If claude
//                exits non-zero while a cap is set, the stop line names the cap.
//   RAVINTIO_ROADMAP_MODEL, RAVINTIO_ROADMAP_MAX_TURNS, PLANIFEST_ROADMAP_MODEL,
//   PLANIFEST_ROADMAP_MAX_TURNS
//                Old names. The driver no longer reads them. If one is set and non-empty,
//                the driver stops before it spawns a step and names the new variable.
//
// Labels: the child's OTEL_RESOURCE_ATTRIBUTES gets these labels appended, with each value
// percent-encoded by scripts/initiative-labels.mjs. The old value stays as it was.
//   work.kind=initiative
//   ravintio.initiative={id}-{slug}
//   ravintio.step={position}
// Only the child sees the change. The labels hold identifiers, never prompt or file text.
//
// Logs: each step writes the child's stdout and stderr, in arrival order, to
// plan/.initiative-logs/step-{position}.log. Each step start will truncate its log, so a
// rerun leaves only the latest attempt. The driver copies the child's stderr to its own
// stderr and never prints the child's stdout or any log content. It excludes the folder
// through .git/info/exclude. The driver refuses a symlink at plan, at the log folder, or at
// the log file, and stops with "I-C Run: Blocked: refused a symlinked step log path". Logs
// are private to the user: the folder has mode 700 and each log mode 600. Every stop after a step starts ends with
// "Log: plan/.initiative-logs/step-{position}.log".
//
// What it does:
//   1. Reads plan/current-initiative/initiative.md and stops unless status is "active".
//   2. Takes plan/.initiative-runner.lock. If the lock exists, it refuses to start
//      and leaves the lock alone.
//   3. Runs `claude -p --output-format stream-json --verbose --permission-mode auto --model {model} [--max-turns {n}]
//      "Run initiative step {position}"`
//      and waits. It never passes --continue or --resume, so each step gets a
//      fresh session. The position goes to claude as one argument, never
//      through a shell.
//   4. After each step it stops if plan/current/build-log.md ends on a
//      "Blocked:" line with no later "Resolved:" line. It runs the same check on
//      plan/_archive/{feature-id}-*/build-log.md, in the newest folder (by name) whose
//      name starts with the step's feature id and that changed after the step started.
//      Ship archives plan/current/ before CI, so a block can sit only in the archive. The
//      driver skips a symlinked archive folder or build log. The stop line is
//      "I-C Run: Blocked: step {n} stopped." plus the message.
//   5. It reads position and status after each step from the initiative branch ref, with
//      `git show {branch}:plan/current-initiative/initiative.md` (0000205 ADR-002). A step
//      that did not merge leaves the branch file unchanged, so the driver stops with
//      "I-C Run: Blocked: step {n} is not merged into the initiative branch, position
//      stayed at {n}". If the ref is unreadable or the root is not a git work tree, it
//      reads the working-tree file. The driver passes git its arguments as an array, with
//      no shell.
//   6. It repeats until delivery: initiative.md is gone and
//      plan/_archive/{id}-{slug}-initiative-*/ exists. It then exits 0.
//      If every step in the "## Steps" table has merged but the archive is not there yet,
//      it prints "I-E Delivery: Pending: all {n} steps merged, initiative delivery runs
//      from the initiative skill" and exits 0 without starting another step.
//
// Child environment: each step session gets CLAUDE_CODE_PRINT_BG_WAIT_CEILING_MS=0, so
// background subagents keep running. A value in the parent environment, even another
// value, wins. Each step session also gets RAVINTIO_INITIATIVE_STEP=1, which the
// auto-trigger hook reads to load the orchestrator and not the initiative skill.
//
// Final report: the driver keeps a list of the steps it ran. At delivery it prints one
// "I-E Delivery: Complete: step {n} merged" line per step, in order. The last line is
// "I-E Delivery: Complete: initiative {id}-{slug} archived, driver done".
//
// Exclusions: the driver adds the lock, the log folder, and plan/.initiative-queue/ to
// .git/info/exclude, so a step never commits the queue folder.
//
// Output: one line per stage, written and flushed at once so a parent session
// can stream it with Monitor. Lines start with "I-C Run:" or "I-D Advance:"
// and the final lines with "I-E Delivery:". A stop line names the reason and,
// for a block, repeats the Blocked: message cut to 500 characters.
//
// Exit codes:
//   0  Delivery is complete.
//   1  A stop: invalid or inactive initiative, existing lock, block, stalled
//      position, failed claude call, or interruption.
//
// The lock is released on every exit path, including SIGINT and SIGTERM.
// The driver never edits the working tree. The steps it launches do that.
// It has no dependencies beyond Node.

import { spawn, spawnSync } from 'node:child_process';
import { appendFileSync, closeSync, constants as fsConstants, existsSync, lstatSync, mkdirSync, openSync, readFileSync, readdirSync, realpathSync, unlinkSync, writeFileSync, writeSync } from 'node:fs';
import { isAbsolute, join, relative, resolve } from 'node:path';
import { withInitiativeLabels } from './initiative-labels.mjs';

const INITIATIVE = 'plan/current-initiative/initiative.md';
const LOCK = 'plan/.initiative-runner.lock';
const LOGS = 'plan/.initiative-logs';
const QUEUE = 'plan/.initiative-queue/';
const BUILD_LOG = 'plan/current/build-log.md';
const ARCHIVE = 'plan/_archive';
const STATUS = /^(proposed|charted|draft|active|blocked|delivered|done)$/;
const POSITION = /^[1-9][0-9]{0,2}$/;
const BRANCH = /^initiative\/([0-9]{7})-([a-z0-9]+(-[a-z0-9]+)*)$/;
const MAX_LINE = 500;
const MODEL = /^[A-Za-z0-9][A-Za-z0-9._:[\]-]{0,63}$/;
const TURNS = /^[1-9][0-9]{0,3}$/;
const DEFAULT_MODEL = 'sonnet';

class Stop extends Error {}

const out = (line) => writeSync(1, `${line}\n`);

function parseArgs(argv) {
  let root = process.cwd();
  for (let i = 0; i < argv.length; i++) {
    if (argv[i] === '--root' && argv[i + 1]) root = argv[++i];
    else throw new Stop(`I-C Run: Blocked: unknown argument "${argv[i].slice(0, 40)}"`);
  }
  return resolve(root);
}

// Reads "name: value" or "- **name:** value" lines. The body wins over the frontmatter,
// because the agent updates the body fields. Falls back to the frontmatter.
// Strips a trailing " # comment" and one matching pair of surrounding quotes.
function field(text, name) {
  const fm = text.match(/^---\r?\n[\s\S]*?\r?\n---\r?\n?/);
  const head = fm ? fm[0] : '';
  const body = text.slice(head.length);
  return fieldIn(body, name) || fieldIn(head, name);
}

function fieldIn(text, name) {
  const re = new RegExp(`^\\s*(?:[-*]\\s+)?\\**${name}\\**\\s*:\\s*\\**\\s*\`?([^\`\\n]*?)\`?\\s*$`, 'mi');
  const m = text.match(re);
  if (!m) return '';
  const v = m[1].replace(/\s+#.*$/, '').trim();
  return /^(["']).*\1$/.test(v) ? v.slice(1, -1).trim() : v;
}

// Old name to new name. A set old variable stops the driver (0000189 REQ-006).
const OLD_VARIABLES = [
  ['RAVINTIO_ROADMAP_MODEL', 'RAVINTIO_INITIATIVE_MODEL'],
  ['PLANIFEST_ROADMAP_MODEL', 'RAVINTIO_INITIATIVE_MODEL'],
  ['RAVINTIO_ROADMAP_MAX_TURNS', 'RAVINTIO_INITIATIVE_MAX_TURNS'],
  ['PLANIFEST_ROADMAP_MAX_TURNS', 'RAVINTIO_INITIATIVE_MAX_TURNS'],
];

// Reads and validates the child settings. The stop lines name the variable, never the value.
function readChildConfig() {
  for (const [old, current] of OLD_VARIABLES) {
    if (process.env[old]) throw new Stop(`I-C Run: Blocked: ${old} is no longer read. Set ${current} instead.`);
  }
  const model = process.env.RAVINTIO_INITIATIVE_MODEL || DEFAULT_MODEL;
  if (!MODEL.test(model)) {
    throw new Stop('I-C Run: Blocked: RAVINTIO_INITIATIVE_MODEL must match ^[A-Za-z0-9][A-Za-z0-9._:[\\]-]{0,63}$');
  }
  const turns = process.env.RAVINTIO_INITIATIVE_MAX_TURNS || '';
  if (turns !== '' && !TURNS.test(turns)) {
    throw new Stop('I-C Run: Blocked: RAVINTIO_INITIATIVE_MAX_TURNS must be a positive integer of up to 4 digits');
  }
  return { model, turns };
}

function readInitiative(root) {
  const file = join(root, INITIATIVE);
  if (!existsSync(file)) throw new Stop(`I-C Run: Blocked: ${INITIATIVE} is missing`);
  return parseInitiative(readFileSync(file, 'utf8'));
}

// Reads initiative.md from the initiative branch ref. Falls back to the working tree if
// the root is not a git work tree or the ref cannot be read.
function readInitiativeFromBranch(root, branch) {
  const inside = spawnSync('git', ['rev-parse', '--is-inside-work-tree'], { cwd: root, encoding: 'utf8' });
  if (!inside.error && inside.status === 0 && inside.stdout.trim() === 'true') {
    const shown = spawnSync('git', ['show', `${branch}:${INITIATIVE}`], { cwd: root, encoding: 'utf8' });
    if (!shown.error && shown.status === 0 && shown.stdout.trim() !== '') return parseInitiative(shown.stdout);
  }
  return readInitiative(root);
}

function parseInitiative(text) {
  const status = field(text, 'status');
  const position = field(text, 'position');
  const branch = field(text, 'branch');
  if (!STATUS.test(status)) throw new Stop('I-C Run: Blocked: initiative status is missing or invalid');
  if (!POSITION.test(position)) throw new Stop('I-C Run: Blocked: initiative position is missing or invalid');
  const b = branch.match(BRANCH);
  if (!b) throw new Stop('I-C Run: Blocked: initiative branch is missing or invalid');
  return { status, position, branch, id: b[1], slug: b[2], text };
}

// Adds the lock path and the log folder to .git/info/exclude so a step session's
// "stage everything" never commits either. Skips quietly outside a git work tree.
function excludeLock(root) {
  const git = (...args) => spawnSync('git', args, { cwd: root, encoding: 'utf8' });
  const inside = git('rev-parse', '--is-inside-work-tree');
  if (inside.error || inside.status !== 0 || inside.stdout.trim() !== 'true') return;
  const p = git('rev-parse', '--git-path', 'info/exclude');
  if (p.status !== 0) return;
  const file = resolve(root, p.stdout.trim());
  let text = existsSync(file) ? readFileSync(file, 'utf8') : '';
  for (const entry of [LOCK, `${LOGS}/`, QUEUE]) {
    if (text.split(/\r?\n/).includes(entry)) continue;
    const add = (text === '' || text.endsWith('\n') ? '' : '\n') + entry + '\n';
    appendFileSync(file, add);
    text += add;
  }
}

// Returns the feature id in the Steps table row for a position, or ''.
function featureIdFor(text, position) {
  for (const line of text.split(/\r?\n/)) {
    const m = line.match(/^\|\s*(\d+)\s*\|\s*([0-9]{7}-[a-z0-9-]+)\s*\|/);
    if (m && m[1] === position) return m[2];
  }
  return '';
}

// Counts the numbered rows in the "## Steps" section. Returns 0 if there is no such section.
function countSteps(text) {
  let inSteps = false;
  let n = 0;
  for (const line of text.split(/\r?\n/)) {
    if (/^##\s/.test(line)) inSteps = /^##\s+Steps\s*$/i.test(line);
    else if (inSteps && /^\|\s*\d+\s*\|/.test(line)) n++;
  }
  return n;
}

// True when the path is a symlink. A missing path is not one.
function isLink(path) {
  try {
    return lstatSync(path).isSymbolicLink();
  } catch {
    return false;
  }
}

// Opens plan/.initiative-logs/step-{position}.log for writing and truncates it.
// Refuses a symlink at plan, at the log folder, or at the log file, and a log folder
// whose real path leaves the real root. The open adds O_NOFOLLOW where the platform has it.
// The folder gets mode 0o700 and the log 0o600. Returns the file descriptor and the
// root-relative path.
function openLog(root, position) {
  const rel = `${LOGS}/step-${position}.log`;
  const refuse = () => new Stop('I-C Run: Blocked: refused a symlinked step log path');
  try {
    const dir = join(root, LOGS);
    for (const part of [join(root, 'plan'), dir]) if (isLink(part)) throw refuse();
    mkdirSync(dir, { recursive: true, mode: 0o700 });
    const rootReal = realpathSync(root);
    const within = relative(rootReal, realpathSync(dir));
    if (within.startsWith('..') || isAbsolute(within)) throw refuse();
    const file = join(root, rel);
    if (isLink(file)) throw refuse();
    const { O_WRONLY, O_CREAT, O_TRUNC, O_NOFOLLOW = 0 } = fsConstants;
    return { fd: openSync(file, O_WRONLY | O_CREAT | O_TRUNC | O_NOFOLLOW, 0o600), rel };
  } catch (e) {
    if (e instanceof Stop) throw e;
    throw new Stop('I-C Run: Blocked: could not open the step log');
  }
}

// Returns the last Blocked: line when no Resolved: line follows it, else null.
// Either line may carry a list marker, such as "- " or "* ".
function openBlock(root) {
  const file = join(root, BUILD_LOG);
  if (!existsSync(file)) return null;
  return blockIn(readFileSync(file, 'utf8'));
}

function blockIn(text) {
  let last = null;
  for (const line of text.split(/\r?\n/)) {
    if (/^\s*(?:[-*+]\s+)?Blocked:/.test(line)) last = line.trim();
    else if (/^\s*(?:[-*+]\s+)?Resolved:/.test(line)) last = null;
  }
  return last === null ? null : last.slice(0, MAX_LINE);
}

// Checks the build log in the newest folder under plan/_archive/ whose name starts with the
// feature id and that changed after the step started. Skips symlinks and paths that leave
// the archive folder.
function archivedBlock(root, featureId, since) {
  if (!featureId) return null;
  try {
    const dir = join(root, ARCHIVE);
    if (isLink(join(root, 'plan')) || isLink(dir) || !existsSync(dir)) return null;
    const names = readdirSync(dir).filter((n) => n.startsWith(featureId)).sort();
    for (let i = names.length - 1; i >= 0; i--) {
      const folder = join(dir, names[i]);
      const st = lstatSync(folder);
      if (st.isSymbolicLink() || !st.isDirectory()) continue;
      if (st.mtimeMs < since) return null;
      const file = join(folder, 'build-log.md');
      const fst = lstatSync(file);
      if (fst.isSymbolicLink() || !fst.isFile()) return null;
      const within = relative(realpathSync(dir), realpathSync(file));
      if (within.startsWith('..') || isAbsolute(within)) return null;
      return blockIn(readFileSync(file, 'utf8'));
    }
  } catch {
    // A missing folder or log means no archived block.
  }
  return null;
}

function delivered(root, id, slug) {
  if (existsSync(join(root, INITIATIVE))) return false;
  const dir = join(root, ARCHIVE);
  if (!existsSync(dir)) return false;
  // Folders archived before 0000192 use the -roadmap- form, so accept both.
  const prefixes = [`${id}-${slug}-initiative-`, `${id}-${slug}-roadmap-`];
  return readdirSync(dir).some((n) => prefixes.some((p) => n.startsWith(p)));
}

function runStep(root, position, cfg, fd, labels) {
  return new Promise((resolveStep) => {
    const bin = process.env.CLAUDE_BIN || 'claude';
    const args = ['-p', '--output-format', 'stream-json', '--verbose', '--permission-mode', 'auto', '--model', cfg.model];
    if (cfg.turns) args.push('--max-turns', cfg.turns);
    args.push(`Run initiative step ${position}`);
    const child = spawn(bin, args, {
      cwd: root,
      env: { ...process.env, CLAUDE_CODE_PRINT_BG_WAIT_CEILING_MS: process.env.CLAUDE_CODE_PRINT_BG_WAIT_CEILING_MS ?? '0', RAVINTIO_INITIATIVE_STEP: '1', OTEL_RESOURCE_ATTRIBUTES: withInitiativeLabels(process.env.OTEL_RESOURCE_ATTRIBUTES, labels.id, labels.slug, position) },
      stdio: ['ignore', 'pipe', 'pipe'],
    });
    activeChild = child;
    child.stdout.on('data', (chunk) => writeSync(fd, chunk));
    child.stderr.on('data', (chunk) => {
      writeSync(fd, chunk);
      writeSync(2, chunk);
    });
    child.on('error', (e) => resolveStep({ error: e.code || 'spawn error' }));
    child.on('close', (code, signal) => resolveStep({ code, signal }));
  });
}

let activeChild = null;
let currentLog = null;

const withLog = (line) => (currentLog ? `${line} Log: ${currentLog}` : line);
let lockPath = null;

function releaseLock() {
  if (!lockPath) return;
  try {
    unlinkSync(lockPath);
  } catch {
    // Already gone.
  }
  lockPath = null;
}

for (const sig of ['SIGINT', 'SIGTERM', 'SIGHUP']) {
  process.on(sig, () => {
    if (activeChild) activeChild.kill(sig);
    releaseLock();
    out(withLog(`I-C Run: Blocked: driver stopped by ${sig}`));
    process.exit(1);
  });
}
process.on('exit', releaseLock);

async function main() {
  const root = parseArgs(process.argv.slice(2));
  const cfg = readChildConfig();
  let rm = readInitiative(root);
  if (rm.status !== 'active') throw new Stop(`I-C Run: Blocked: initiative status is ${rm.status}, not active`);
  const { id, slug } = rm;

  const lock = join(root, LOCK);
  excludeLock(root);
  try {
    writeFileSync(lock, `${process.pid}\n`, { flag: 'wx' });
  } catch (e) {
    if (e.code === 'EEXIST') throw new Stop(`I-C Run: Blocked: ${LOCK} exists, another driver may be running`);
    throw e;
  }
  lockPath = lock;

  const ran = [];
  for (;;) {
    const position = rm.position;
    const featureId = featureIdFor(rm.text, position);
    const started = Date.now();
    currentLog = null;
    const log = openLog(root, position);
    currentLog = log.rel;
    out(`I-C Run: Starting: initiative step ${position} in a fresh session`);
    let res;
    try {
      res = await runStep(root, position, cfg, log.fd, { id, slug });
    } finally {
      closeSync(log.fd);
    }
    activeChild = null;
    if (res.error) throw new Stop(`I-C Run: Blocked: could not start claude (${res.error})`);
    if (res.code !== 0) {
      const cap = cfg.turns ? `. The step may have reached RAVINTIO_INITIATIVE_MAX_TURNS=${cfg.turns}` : '';
      throw new Stop(`I-C Run: Blocked: claude exited ${res.code ?? res.signal} on step ${position}${cap}`);
    }
    ran.push(position);

    if (delivered(root, id, slug)) {
      reportSteps(ran);
      out(`I-E Delivery: Complete: initiative ${id}-${slug} archived, driver done`);
      return;
    }
    const block = openBlock(root) || archivedBlock(root, featureId, started - 1000);
    if (block) throw new Stop(`I-C Run: Blocked: step ${position} stopped. ${block}`);

    rm = readInitiativeFromBranch(root, rm.branch);
    if (rm.position === position) {
      throw new Stop(`I-C Run: Blocked: step ${position} is not merged into the initiative branch, position stayed at ${position}`);
    }
    if (rm.status !== 'active') throw new Stop(`I-C Run: Blocked: initiative status is ${rm.status}, not active`);
    const total = countSteps(rm.text);
    if (total > 0 && Number(rm.position) > total) {
      reportSteps(ran);
      out(`I-E Delivery: Pending: all ${total} steps merged, initiative delivery runs from the initiative skill`);
      return;
    }
    out(`I-D Advance: Complete: step ${position} done, position now ${rm.position}`);
  }
}

function reportSteps(ran) {
  for (const n of ran) out(`I-E Delivery: Complete: step ${n} merged`);
}

main().then(
  () => process.exit(0),
  (e) => {
    out(e instanceof Stop ? withLog(e.message) : `I-C Run: Blocked: driver error ${e.code || e.name}`);
    process.exit(1);
  },
);
