#!/usr/bin/env node
// Reserves a block of ids from a counter file under an exclusive lock (0000199).
//
// Usage: node reserve-id.mjs [qty] [--file path] [--init] [--commit]
//   qty     how many ids to reserve, 1 to 1000. Default 1.
//   --file  the counter file. Default plan/backlog/.next-id under the current folder.
//   --init  if the counter is missing, create it from the highest id in the
//           backlog, archive, changelog, and roadmap folders beside it, plus one.
//   --commit  after the reservation, commit the counter file alone (0000247).
//
// Prints one id per line and exits 0. On any failure it prints one line to
// stderr and exits 1. A failure before the counter write leaves the counter as
// it was. A failed --commit keeps the new counter value, so no id is reused.

import fs from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';

const MAX_QTY = 1000;
const LOCK_WAIT_MS = 5000;
const LOCK_POLL_MS = 20;

function fail(message) {
  process.stderr.write(`reserve-id: ${message}\n`);
  process.exit(1);
}

function parseArgs(argv) {
  const opts = { qty: 1, file: path.join('plan', 'backlog', '.next-id'), init: false, commit: false };
  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];
    if (arg === '--init') opts.init = true;
    else if (arg === '--commit') opts.commit = true;
    else if (arg === '--file') {
      if (i + 1 >= argv.length) fail('--file needs a path');
      opts.file = argv[++i];
    } else if (/^\d+$/.test(arg)) opts.qty = Number(arg);
    else fail(`quantity must be an integer from 1 to ${MAX_QTY}`);
  }
  if (opts.qty < 1 || opts.qty > MAX_QTY) fail(`quantity must be an integer from 1 to ${MAX_QTY}`);
  return opts;
}

function sleep(ms) {
  Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, ms);
}

function takeLock(lockPath) {
  const deadline = Date.now() + LOCK_WAIT_MS;
  for (;;) {
    try {
      return fs.openSync(lockPath, 'wx');
    } catch (err) {
      if (err.code !== 'EEXIST') fail(`could not take the lock at ${lockPath}: ${err.code}`);
      if (Date.now() >= deadline) fail(`the lock at ${lockPath} is held. If no reservation is running, remove it`);
      sleep(LOCK_POLL_MS);
    }
  }
}

function isSymlink(p) {
  try {
    return fs.lstatSync(p).isSymbolicLink();
  } catch {
    return false;
  }
}

// The highest leading number in a folder or file name under the plan folders beside the counter.
function highestId(planDir) {
  let highest = 0;
  for (const sub of ['backlog', '_archive', 'changelog', 'roadmap']) {
    let names = [];
    try {
      names = fs.readdirSync(path.join(planDir, sub));
    } catch {
      continue;
    }
    for (const name of names) {
      const m = /^(\d{7})(?:-|\.|$)/.exec(name);
      if (m) highest = Math.max(highest, Number(m[1]));
    }
  }
  return highest;
}

function writeCounter(file, value, width) {
  const tmp = `${file}.tmp-${process.pid}`;
  fs.writeFileSync(tmp, `${String(value).padStart(width, '0')}\n`, { flag: 'wx' });
  fs.renameSync(tmp, file);
}

const opts = parseArgs(process.argv.slice(2));
const file = path.resolve(opts.file);
const lockPath = `${file}.lock`;

if (isSymlink(file)) fail(`${file} is a symlink`);
if (isSymlink(lockPath)) fail(`${lockPath} is a symlink`);

// Runs under the lock. It throws instead of exiting, so the caller releases the lock first.
function reserve() {
  let width = 7;
  let next;
  if (fs.existsSync(file)) {
    const text = fs.readFileSync(file, 'utf8').trim();
    if (!/^\d+$/.test(text)) throw new Error(`${file} does not hold a number`);
    width = text.length;
    next = Number(text);
  } else if (opts.init) {
    next = highestId(path.dirname(path.dirname(file))) + 1;
  } else {
    throw new Error(`${file} does not exist. Run with --init to create it`);
  }
  const after = next + opts.qty;
  if (String(after).length > width) throw new Error(`reserving ${opts.qty} ids overflows ${width} digits`);
  writeCounter(file, after, width);
  const ids = [];
  for (let n = next; n < after; n++) ids.push(String(n).padStart(width, '0'));
  return ids;
}

// Commits the counter file alone. The path after the double dash limits the
// commit to that file, whatever else is staged.
function commitCounter(reserved) {
  const dir = path.dirname(file);
  const subject = reserved.length === 1
    ? `chore(ids): reserve id ${reserved[0]}`
    : `chore(ids): reserve ids ${reserved[0]} to ${reserved[reserved.length - 1]}`;
  try {
    execFileSync('git', ['add', '--', file], { cwd: dir, stdio: 'pipe' });
    execFileSync('git', ['commit', '-m', subject, '--', file], { cwd: dir, stdio: 'pipe' });
  } catch {
    fail('the ids stay reserved, but git could not commit the counter file');
  }
}

if (opts.init) fs.mkdirSync(path.dirname(file), { recursive: true });
const lockFd = takeLock(lockPath);
let ids;
let failure;
try {
  ids = reserve();
} catch (err) {
  failure = err.message;
} finally {
  fs.closeSync(lockFd);
  fs.rmSync(lockPath, { force: true });
}
if (failure) fail(failure);
if (opts.commit) commitCounter(ids);
process.stdout.write(`${ids.join('\n')}\n`);
