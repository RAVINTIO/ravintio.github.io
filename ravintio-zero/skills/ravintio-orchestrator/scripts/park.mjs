#!/usr/bin/env node
// park.mjs - the git and gh steps of the orchestrator's park command (ADR-005).
//
// Usage, run from the repository root:
//
//   node park.mjs park      --entry <file> --backlog-id <id> [--slug <slug>] [--feature-id <id>] [--branch <name>]
//   node park.mjs finish-pr --entry <file> --backlog-id <id> [--slug <slug>] [--feature-id <id>] [--branch <name>]
//   node park.mjs resume    <branch>
//   node park.mjs discard   <branch> --confirmed
//
// Arguments:
//   --entry       A filled backlog entry with status "parked". It must name the
//                 branch in a "**Parked branch:** {branch}" line. Keep it outside
//                 the working tree, or it travels across branch switches.
//   --backlog-id  The next backlog id. The entry lands at
//                 plan/backlog/{backlog-id}-park-{slug}/entry.md.
//   --slug        Defaults to the feature id without its leading number.
//   --feature-id  Defaults to the branch name without its "feat/" prefix.
//   --branch      The feature branch. Defaults to the current branch.
//   --confirmed   Pass it to discard only after the human confirms.
//
// Subcommands:
//   park       Checks that plan/current/park.md is committed, pushes the
//              feature branch, then runs the finish-pr steps.
//   finish-pr  If gh finds no PR for chore/park-{feature-id}, cuts that branch
//              from origin/main, commits the entry, pushes, and runs
//              gh pr create. It then checks out main.
//   resume     Checks out the branch and merges origin/main into it. It leaves
//              plan/current/park.md for the skill to restore.
//   discard    Deletes the branch locally and on origin.
//
// Validation runs before any git call that changes state:
//   - Every branch the script takes or derives must pass one check. That
//     covers the feature branch, the chore branch, and the resume and discard
//     argument. The check rejects a leading "-" or "+", a "refs/" or "heads/"
//     prefix, main, HEAD, and any name that git check-ref-format --branch
//     rejects. A refused branch prints one fixed error line and exits 1.
//   - --backlog-id must be seven digits. --slug must be lower-case words of
//     letters and digits joined by single hyphens. The entry path must stay
//     under plan/backlog/.
//   - Pushes and remote deletes use exact refspecs under refs/heads/, so git
//     never reads a branch name as an option, a forced push, or another ref.
//
// If a git or gh call fails, the script prints the exact error and exits 1.
// Park refuses a symlink in plan, plan/backlog, the entry folder, or entry.md,
// and any real path outside plan/backlog/, before it writes or deletes (ADR-008).
// A failed park or finish-pr returns the working tree to the feature branch.
// If the entry's add or commit fails, the script first unstages and deletes
// the entry. A failed cleanup step never replaces the original error.
// The script never merges a pull request, never commits to main, and never
// force-pushes. It has no dependencies beyond Node and the git and gh tools.

import { spawnSync } from 'node:child_process';
import { existsSync, lstatSync, mkdirSync, readFileSync, realpathSync, rmSync, writeFileSync } from 'node:fs';
import { basename, dirname, isAbsolute, join, relative, resolve } from 'node:path';

const REMOTE = 'origin';
const MAIN = 'main';
const PARK_RECORD = 'plan/current/park.md';
const BACKLOG_DIR = 'plan/backlog';
const BACKLOG_ID = /^[0-9]{7}$/;
const SLUG = /^[a-z0-9]+(-[a-z0-9]+)*$/;
const BAD_BRANCH = 'Refusing an invalid branch name. Use a plain branch name that is not main.';

class ParkError extends Error {}

function run(cmd, args, { allowFail = false } = {}) {
  const r = spawnSync(cmd, args, { encoding: 'utf8' });
  if (r.error) throw new ParkError(`${cmd} ${args.join(' ')} could not start: ${r.error.message}`);
  if (r.status !== 0 && !allowFail) {
    const detail = `${r.stderr || ''}${r.stdout || ''}`.trim();
    throw new ParkError(`${cmd} ${args.join(' ')} failed (exit ${r.status}):\n${detail}`);
  }
  return { ok: r.status === 0, out: (r.stdout || '').trim() };
}
const git = (...args) => run('git', args).out;
const gitOk = (...args) => run('git', args, { allowFail: true }).ok;
const currentBranch = () => git('branch', '--show-current');

// One check for every branch the script takes or derives. It runs before any
// git call that changes state, and it prints a fixed line that never echoes the name.
function checkBranch(name) {
  const bad = !name
    || /^[-+]/.test(name)
    || /^(refs|heads)\//.test(name)
    || name === MAIN
    || name === 'HEAD'
    || spawnSync('git', ['check-ref-format', '--branch', name], { encoding: 'utf8' }).status !== 0;
  if (bad) throw new ParkError(BAD_BRANCH);
  return name;
}
const headRef = (branch) => `refs/heads/${branch}`;
const pushSpec = (branch) => `${headRef(branch)}:${headRef(branch)}`;

function parseArgs(argv) {
  const opts = { positional: [] };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--confirmed') opts.confirmed = true;
    else if (a.startsWith('--')) {
      const value = argv[++i];
      if (value === undefined) throw new ParkError(`${a} needs a value.`);
      opts[a.slice(2)] = value;
    } else opts.positional.push(a);
  }
  return opts;
}

function parkContext(opts) {
  const branch = opts.branch || currentBranch();
  if (!branch || branch === MAIN) throw new ParkError(`Park runs from a feature branch, not "${branch || 'detached HEAD'}".`);
  checkBranch(branch);
  const featureId = opts['feature-id'] || branch.replace(/^feat\//, '');
  const chore = checkBranch(`chore/park-${featureId}`);
  const slug = opts.slug || featureId.replace(/^\d+-/, '');
  if (!opts.entry) throw new ParkError('--entry <file> is required.');
  if (!opts['backlog-id']) throw new ParkError('--backlog-id <id> is required.');
  if (!BACKLOG_ID.test(opts['backlog-id'])) throw new ParkError('--backlog-id must be seven digits.');
  if (!SLUG.test(slug)) throw new ParkError('--slug must be lower-case letters and digits joined by single hyphens.');
  const entryPath = `${BACKLOG_DIR}/${opts['backlog-id']}-park-${slug}/entry.md`;
  const fromBacklog = relative(resolve(BACKLOG_DIR), resolve(entryPath));
  if (!fromBacklog || fromBacklog.startsWith('..') || isAbsolute(fromBacklog)) {
    throw new ParkError(`The entry path must stay under ${BACKLOG_DIR}/.`);
  }
  // A failed commit deletes the target path, so it must never hold the only copy.
  if (resolve(opts.entry) === resolve(entryPath)) {
    throw new ParkError(`--entry must not be the target path ${entryPath}. Write the entry outside the working tree.`);
  }
  if (!existsSync(opts.entry)) throw new ParkError(`Entry file not found: ${opts.entry}`);
  const entry = readFileSync(opts.entry, 'utf8');
  if (!entry.includes(`**Parked branch:** ${branch}`)) {
    throw new ParkError(`The entry must name the branch: "**Parked branch:** ${branch}".`);
  }
  return {
    branch,
    featureId,
    chore,
    entry,
    entryPath,
  };
}

// One park per working tree: refuse while another feature's chore branch exists.
function checkSinglePark(ctx) {
  const others = git('branch', '--list', 'chore/park-*', '--format=%(refname:short)')
    .split('\n').filter((b) => b && b !== ctx.chore);
  if (others.length) {
    throw new ParkError(`Another park is open in this working tree: ${others.join(', ')}. Finish or remove it first.`);
  }
}

function commitOffMain(message) {
  if (currentBranch() === MAIN) throw new ParkError('Refusing to commit to main.');
  git('commit', '-m', message);
}

// Resolves a path that may not exist yet: the nearest existing ancestor's real
// path, plus the names that are still missing.
function realPathOrAncestor(path) {
  const missing = [];
  let current = resolve(path);
  while (!existsSync(current) && !isLink(current)) {
    missing.unshift(basename(current));
    current = dirname(current);
  }
  return join(realpathSync(current), ...missing);
}
function isLink(path) {
  try {
    return lstatSync(path).isSymbolicLink();
  } catch {
    return false;
  }
}

// Refuses a symlink in any part of the entry path, and any path whose real
// location leaves the real plan/backlog/. The chore branch comes from origin/main,
// so its tree is untrusted. It runs right before each write, mkdir, or delete.
// The message names the repo-relative part only, never the link target.
function checkEntryPath(ctx) {
  const dir = dirname(ctx.entryPath);
  for (const part of ['plan', BACKLOG_DIR, dir, ctx.entryPath]) {
    if (isLink(part)) throw new ParkError(`Refusing ${part.slice(0, 200)}: it is a symlink.`);
  }
  const root = realPathOrAncestor(BACKLOG_DIR);
  const fromRoot = relative(root, realPathOrAncestor(ctx.entryPath));
  if (!fromRoot || fromRoot.startsWith('..') || isAbsolute(fromRoot)) {
    throw new ParkError(`Refusing ${dir.slice(0, 200)}: it leaves ${BACKLOG_DIR}/.`);
  }
}

// Unstages and deletes the entry after a failed add or commit. Each step
// swallows its own failure, so the caller always rethrows the original error.
function removeEntry(ctx) {
  run('git', ['reset', '-q', '--', ctx.entryPath], { allowFail: true });
  try {
    checkEntryPath(ctx);
    rmSync(ctx.entryPath, { force: true });
  } catch {
    // The original error matters more than a failed delete.
  }
}

function finishPr(ctx) {
  const existing = run('gh', ['pr', 'list', '--head', ctx.chore, '--state', 'all']).out;
  if (existing) {
    console.log(`A PR for ${ctx.chore} already exists. Skipping the chore branch.`);
  } else {
    git('fetch', REMOTE, MAIN);
    const remoteChore = `refs/remotes/${REMOTE}/${ctx.chore}`;
    gitOk('fetch', REMOTE, `refs/heads/${ctx.chore}:${remoteChore}`);
    const base = gitOk('rev-parse', '-q', '--verify', remoteChore) ? remoteChore : `${REMOTE}/${MAIN}`;
    git('checkout', '-B', ctx.chore, base);
    checkEntryPath(ctx);
    mkdirSync(dirname(ctx.entryPath), { recursive: true });
    checkEntryPath(ctx);
    writeFileSync(ctx.entryPath, ctx.entry);
    try {
      git('add', '--', ctx.entryPath);
      if (!gitOk('diff', '--cached', '--quiet')) {
        commitOffMain(`chore(backlog): park ${ctx.featureId}`);
      }
    } catch (err) {
      removeEntry(ctx);
      throw err;
    }
    git('push', '-u', REMOTE, pushSpec(ctx.chore));
    const url = run('gh', [
      'pr', 'create', '--base', MAIN, '--head', ctx.chore,
      '--title', `chore(backlog): park ${ctx.featureId}`,
      '--body', `Files the parked backlog entry for ${ctx.branch}. The work stays on that branch.`,
    ]).out;
    if (url) console.log(url);
  }
  git('checkout', MAIN);
  console.log(`Parked ${ctx.branch}. The working tree is on ${MAIN}.`);
}

// Runs a park step, and on failure returns the working tree to the feature branch.
function onFeatureBranch(ctx, step) {
  try {
    step();
  } catch (err) {
    if (currentBranch() !== ctx.branch) {
      const back = run('git', ['checkout', ctx.branch], { allowFail: true });
      if (!back.ok) err.message += `\nCould not return to ${ctx.branch}. Check out the branch by hand.`;
    }
    throw err;
  }
}

function park(opts) {
  const ctx = parkContext(opts);
  if (currentBranch() !== ctx.branch) throw new ParkError(`Check out ${ctx.branch} before you park it.`);
  checkSinglePark(ctx);
  if (!gitOk('ls-files', '--error-unmatch', '--', PARK_RECORD)) {
    throw new ParkError(`${PARK_RECORD} is not committed on ${ctx.branch}.`);
  }
  if (git('status', '--porcelain', '--', PARK_RECORD)) {
    throw new ParkError(`${PARK_RECORD} has uncommitted changes. Commit it first.`);
  }
  onFeatureBranch(ctx, () => {
    git('push', '-u', REMOTE, pushSpec(ctx.branch));
    finishPr(ctx);
  });
}

function finishPrCommand(opts) {
  const ctx = parkContext(opts);
  if (currentBranch() !== ctx.branch) throw new ParkError(`Check out ${ctx.branch} before you run finish-pr.`);
  checkSinglePark(ctx);
  onFeatureBranch(ctx, () => finishPr(ctx));
}

function resume(opts) {
  const [branch] = opts.positional;
  if (!branch) throw new ParkError('resume needs a branch name.');
  checkBranch(branch);
  git('fetch', REMOTE);
  git('checkout', '--end-of-options', branch);
  git('merge', '--no-edit', `${REMOTE}/${MAIN}`);
  console.log(`Resumed ${branch} with ${REMOTE}/${MAIN} merged. Restore state from ${PARK_RECORD}.`);
}

function discard(opts) {
  const [branch] = opts.positional;
  if (!branch) throw new ParkError('discard needs a branch name.');
  checkBranch(branch);
  if (!opts.confirmed) throw new ParkError(`Discard deletes ${branch}. Pass --confirmed only after the human confirms.`);
  if (currentBranch() === branch) throw new ParkError(`Check out ${MAIN} before you discard ${branch}.`);
  if (gitOk('rev-parse', '-q', '--verify', headRef(branch))) git('branch', '-D', '--end-of-options', branch);
  if (git('ls-remote', '--heads', REMOTE, headRef(branch))) git('push', REMOTE, `:${headRef(branch)}`);
  console.log(`Discarded ${branch} locally and on ${REMOTE}.`);
}

const COMMANDS = { park, 'finish-pr': finishPrCommand, resume, discard };

try {
  const [cmd, ...rest] = process.argv.slice(2);
  const handler = COMMANDS[cmd];
  if (!handler) throw new ParkError(`Unknown subcommand "${cmd ?? ''}". Use park, finish-pr, resume, or discard.`);
  handler(parseArgs(rest));
} catch (err) {
  console.error(`park: ${err instanceof ParkError ? err.message : err.stack}`);
  process.exit(1);
}
