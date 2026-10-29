#!/usr/bin/env node
// initiative-watch.mjs - read-only progress watcher for an initiative run (0000205 REQ-003).
//
// Usage, run from the repository root:
//
//   node ravintio-zero/scripts/initiative-watch.mjs [--root <dir>] [--once]
//
// Arguments:
//   --root <dir>   The working tree that holds plan/. Defaults to the current directory.
//   --once         Run one pass, print the heartbeat, and exit 0.
//   --since-lines <n>
//                  Test aid, with --once. Treat the first n lines of the watched build log
//                  as already seen, to simulate an earlier pass.
//   --since-commit <sha>
//                  Test aid, with --once. Treat commits up to and including sha as already
//                  seen, to simulate an earlier pass.
//   --since-bytes <n>
//                  Test aid, with --once. Treat the first n bytes of the step log as already
//                  seen. Without it the first pass starts at the end of the log.
//   --passes <n>   Test aid, with --once. Run n passes in one process, then exit 0.
//   --now <iso>    Test aid. Use this time as the clock instead of the system clock.
//   There is no --state flag. The script keeps its state in memory and writes no file.
//
// What it does:
//   Every POLL_MS it reads plan/current/build-log.md (or the newest archived build log when
//   the current one is gone) and `git log`. It prints one line per event, each starting with
//   "I-C Run: event:". The events are:
//     - a new "Complete:" line, such as "P1 Plan: Complete: ..."
//     - a new "Blocked:" line
//     - a new "Resolved:" line
//     - a new commit, with its subject only
//   When the watched build log is a different file from the last pass, it also prints the
//   "Complete:" lines already in the new file.
//
//   Activity: the driver starts each step with --output-format stream-json, so the step log
//   (plan/.initiative-logs/step-{position}.log) holds one JSON event per line. The watcher
//   reads new bytes of that log each pass and prints one "I-C Run: activity: ..." line per
//   tool call ("tool: {name} {detail}"), subagent start ("agent: started {type} {description}"),
//   and assistant text ("text: {first line}"), in the order received. Each line is cut to
//   200 characters in total. A partial last line waits for the next pass. A line that is
//   not valid JSON or has an unknown shape is skipped. Tool results are never printed.
//
//   Stale log: if a commit is at least STALE_MS newer than the build log and the build log has
//   not changed for STALE_MS, it prints "I-C Run: stale: ...". It prints each stale state once.
//   The state is the log modification time plus the newest commit, kept in memory only.
//
//   Branch change: commits are listed with `git log {last-seen}..HEAD` when the last-seen
//   commit is an ancestor of HEAD. If it is not, or git does not know it, the watcher prints
//   one "I-C Run: event: branch changed to {branch}" line and no commit lines.
//
//   Heartbeat: every HEARTBEAT_MS it prints "I-C Run: heartbeat: ..." with the step (the
//   position in plan/current-initiative/initiative.md), the phase (the last "### P<n>:"
//   heading), the last build log line cut to 200 characters, the time since the last change,
//   and whether plan/.initiative-runner.lock is held. With --once it always prints one.
//
//   Delivery: when the lock file and the initiative file are both gone, it prints one
//   "I-E Delivery: ..." line and exits 0.
//
// Safety: it writes no file. It runs only `git log`, `git rev-parse`, `git merge-base
// --is-ancestor`, and `git branch --show-current`, through spawnSync with an argument array. It refuses a
// symlink at plan, at plan/current, at plan/_archive, or at any file it reads, and stops with
// "I-C Run: Blocked: refused a symlinked plan path". Every line is cut to 500 characters.
//
// Exit codes:
//   0  Delivery is complete, or --once finished.
//   1  A bad argument or a refused symlink.
//
// It has no dependencies beyond Node.

import { spawnSync } from 'node:child_process';
import { closeSync, existsSync, lstatSync, openSync, readFileSync, readSync, readdirSync, statSync, writeSync } from 'node:fs';
import { join, resolve } from 'node:path';

const POLL_MS = 10000;
const HEARTBEAT_MS = 300000;
const STALE_MS = 900000;
const MAX_LINE = 500;
const MAX_TAIL = 200;
const MAX_ACTIVITY = 200;
const LOGS = 'plan/.initiative-logs';
const MAX_COMMITS = 100;

const INITIATIVE = 'plan/current-initiative/initiative.md';
const LOCK = 'plan/.initiative-runner.lock';
const BUILD_LOG = 'plan/current/build-log.md';
const ARCHIVE = 'plan/_archive';

class Stop extends Error {}

const cut = (text, max) => (text.length > max ? text.slice(0, max) : text);
const out = (line) => {
  try {
    writeSync(1, `${cut(line, MAX_LINE)}\n`);
  } catch {
    // A closed pipe must not stop the watcher with a stack trace.
  }
};

function parseArgs(argv) {
  const opts = { root: process.cwd(), once: false, sinceLines: null, sinceCommit: null, sinceBytes: null, now: null, passes: 1 };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--once') opts.once = true;
    else if (a === '--root' && argv[i + 1]) opts.root = argv[++i];
    else if (a === '--since-lines' && /^[0-9]{1,9}$/.test(argv[i + 1] || '')) opts.sinceLines = Number(argv[++i]);
    else if (a === '--since-commit' && /^[0-9a-f]{4,64}$/i.test(argv[i + 1] || '')) opts.sinceCommit = argv[++i];
    else if (a === '--since-bytes' && /^[0-9]{1,12}$/.test(argv[i + 1] || '')) opts.sinceBytes = Number(argv[++i]);
    else if (a === '--passes' && /^[1-9][0-9]{0,2}$/.test(argv[i + 1] || '')) opts.passes = Number(argv[++i]);
    else if (a === '--now' && argv[i + 1] && !Number.isNaN(Date.parse(argv[i + 1]))) opts.now = Date.parse(argv[++i]);
    else throw new Stop(`I-C Run: Blocked: unknown argument "${a.slice(0, 40)}"`);
  }
  opts.root = resolve(opts.root);
  return opts;
}

// Reads "name: value" or "- **name:** value" lines, as initiative-run.mjs does.
function field(text, name) {
  const fm = text.match(/^---\r?\n[\s\S]*?\r?\n---\r?\n?/);
  const head = fm ? fm[0] : '';
  return fieldIn(text.slice(head.length), name) || fieldIn(head, name);
}

function fieldIn(text, name) {
  const re = new RegExp(`^\\s*(?:[-*]\\s+)?\\**${name}\\**\\s*:\\s*\\**\\s*\`?([^\`\\n]*?)\`?\\s*$`, 'mi');
  const m = text.match(re);
  if (!m) return '';
  const v = m[1].replace(/\s+#.*$/, '').trim();
  return /^(["']).*\1$/.test(v) ? v.slice(1, -1).trim() : v;
}

function isLink(path) {
  try {
    return lstatSync(path).isSymbolicLink();
  } catch {
    return false;
  }
}

// Throws a Stop if the path or any folder on the way down from root is a symlink.
function refuseLinks(root, rel) {
  let p = root;
  for (const part of rel.split('/')) {
    p = join(p, part);
    if (isLink(p)) throw new Stop('I-C Run: Blocked: refused a symlinked plan path');
  }
}

function readText(root, rel) {
  refuseLinks(root, rel);
  const file = join(root, rel);
  return existsSync(file) ? readFileSync(file, 'utf8') : null;
}

// The newest archived build log by modification time, as a relative path, or ''.
function newestArchived(root) {
  refuseLinks(root, ARCHIVE);
  const dir = join(root, ARCHIVE);
  if (!existsSync(dir)) return '';
  let best = '';
  let bestTime = -1;
  for (const name of readdirSync(dir)) {
    const rel = `${ARCHIVE}/${name}/build-log.md`;
    if (isLink(join(dir, name))) throw new Stop('I-C Run: Blocked: refused a symlinked plan path');
    const file = join(root, rel);
    if (!existsSync(file)) continue;
    refuseLinks(root, rel);
    const t = statSync(file).mtimeMs;
    if (t > bestTime) {
      bestTime = t;
      best = rel;
    }
  }
  return best;
}

function git(root, args) {
  const r = spawnSync('git', ['-C', root, ...args], { encoding: 'utf8' });
  return r.status === 0 ? r.stdout : '';
}

// Newest first: [{ sha, time (ms), subject }]. A range such as "abc..HEAD" is optional.
function readCommits(root, range = null, max = MAX_COMMITS) {
  const text = git(root, ['log', `-n${max}`, '--format=%H%x09%ct%x09%s', ...(range ? [range] : [])]);
  return text.split('\n').filter(Boolean).map((l) => {
    const [sha, ct, ...rest] = l.split('\t');
    return { sha, time: Number(ct) * 1000, subject: rest.join('\t') };
  });
}

function gitOk(root, args) {
  return spawnSync('git', ['-C', root, ...args], { encoding: 'utf8' }).status === 0;
}

function eventLine(line) {
  const t = line.trim().replace(/^[-*#>\s]+/, '');
  if (/\bBlocked:/.test(t) && !/\bComplete:/.test(t)) return t;
  if (/\bResolved:/.test(t) && !/\bComplete:/.test(t)) return t;
  if (/\bComplete:/.test(t)) return t;
  return '';
}

function ago(ms) {
  const m = Math.max(0, Math.floor(ms / 60000));
  return m < 1 ? 'under 1 minute' : `${m} minute${m === 1 ? '' : 's'}`;
}

const state = { path: null, seen: 0, head: null, lastBeat: null, staleKey: null, logPath: null, logOffset: 0, logRest: '' };

// Collapses control characters and whitespace runs to one space.
const oneLine = (text) => String(text).replace(/[\u0000-\u001f\u007f]+/g, ' ').replace(/\s+/g, ' ').trim();

// The first string input worth showing for a tool call.
function toolDetail(input) {
  if (!input || typeof input !== 'object') return '';
  for (const k of ['command', 'file_path', 'path', 'pattern', 'url', 'query', 'description', 'prompt']) {
    if (typeof input[k] === 'string' && input[k] !== '') return input[k];
  }
  return '';
}

// Turns one parsed stream event into zero or more summaries.
function summarise(event) {
  const out = [];
  if (!event || event.type !== 'assistant' || !event.message || !Array.isArray(event.message.content)) return out;
  for (const item of event.message.content) {
    if (!item || typeof item !== 'object') continue;
    if (item.type === 'tool_use' && typeof item.name === 'string') {
      const input = item.input || {};
      if (item.name === 'Task' || item.name === 'Agent') {
        out.push(`agent: started ${oneLine(input.subagent_type ?? '')} ${oneLine(input.description ?? '')}`.trim());
      } else {
        out.push(`tool: ${item.name} ${oneLine(toolDetail(input).split('\n')[0])}`.trim());
      }
    } else if (item.type === 'text' && typeof item.text === 'string' && item.text.trim() !== '') {
      out.push(`text: ${oneLine(item.text.trim().split('\n')[0])}`);
    }
  }
  return out;
}

// Prints the activity lines for stream events added to the step log since the last pass.
function activity(opts, rel) {
  if (!existsSync(join(opts.root, rel))) return;
  refuseLinks(opts.root, rel);
  const file = join(opts.root, rel);
  const size = statSync(file).size;
  if (state.logPath !== rel) {
    state.logPath = rel;
    state.logOffset = Math.min(opts.sinceBytes ?? size, size);
    state.logRest = '';
  }
  if (size < state.logOffset) {
    state.logOffset = 0;
    state.logRest = '';
  }
  if (size === state.logOffset) return;
  const fd = openSync(file, 'r');
  let chunk;
  try {
    chunk = Buffer.alloc(size - state.logOffset);
    readSync(fd, chunk, 0, chunk.length, state.logOffset);
  } finally {
    closeSync(fd);
  }
  state.logOffset = size;
  const lines = (state.logRest + chunk.toString('utf8')).split('\n');
  state.logRest = lines.pop();
  for (const l of lines) {
    if (l.trim() === '') continue;
    let event;
    try {
      event = JSON.parse(l);
    } catch {
      continue;
    }
    for (const s of summarise(event)) out(cut(`I-C Run: activity: ${s}`, MAX_ACTIVITY));
  }
}

function pass(opts) {
  const root = opts.root;
  const now = opts.now ?? Date.now();
  refuseLinks(root, 'plan');

  const initText = readText(root, INITIATIVE);
  const lockHeld = existsSync(join(root, LOCK));
  refuseLinks(root, LOCK);
  if (initText === null && !lockHeld) {
    out('I-E Delivery: the lock and the initiative file are gone. The run is complete.');
    return true;
  }

  let rel = existsSync(join(root, BUILD_LOG)) ? BUILD_LOG : newestArchived(root);
  let logText = rel ? readText(root, rel) : null;
  if (logText === null) rel = '';
  const lines = logText === null ? [] : logText.split(/\r?\n/);
  while (lines.length && lines[lines.length - 1] === '') lines.pop();
  const mtime = rel ? statSync(join(root, rel)).mtimeMs : null;

  // Build log events.
  if (rel) {
    if (state.path !== null && state.path !== rel) {
      for (const l of lines) if (/\bComplete:/.test(l)) out(`I-C Run: event: ${eventLine(l)}`);
    } else {
      // First pass: --since-lines if given, else treat the existing lines as seen.
      const first = opts.sinceLines ?? lines.length;
      const from = state.path === null ? first : state.seen;
      const start = from > lines.length ? lines.length : from;
      for (const l of lines.slice(start)) {
        const e = eventLine(l);
        if (e) out(`I-C Run: event: ${e}`);
      }
    }
    state.path = rel;
    state.seen = lines.length;
  }

  // Step log activity.
  const position = initText === null ? '' : field(initText, 'position');
  if (/^[0-9]{1,4}$/.test(position)) activity(opts, `${LOGS}/step-${position}.log`);

  // Commit events. A last-seen commit that is not an ancestor of HEAD means the branch changed.
  const head = git(root, ['rev-parse', 'HEAD']).trim();
  if (/^[0-9a-f]{40,64}$/.test(head)) {
    const base = state.head ?? opts.sinceCommit;
    if (base && !head.startsWith(base)) {
      if (gitOk(root, ['merge-base', '--is-ancestor', base, 'HEAD'])) {
        for (const c of readCommits(root, `${base}..HEAD`).reverse()) out(`I-C Run: event: commit ${c.sha.slice(0, 7)} ${c.subject}`);
      } else {
        const branch = git(root, ['branch', '--show-current']).trim();
        out(`I-C Run: event: branch changed to ${oneLine(branch) || 'a detached HEAD'}`);
      }
    }
    state.head = head;
  }

  // Stale log: report each stale state once.
  const [latest] = readCommits(root, null, 1);
  if (mtime !== null && latest && latest.time - mtime >= STALE_MS && now - mtime > STALE_MS) {
    const key = `${mtime}:${latest.sha}`;
    if (key !== state.staleKey) {
      state.staleKey = key;
      out(`I-C Run: stale: the build log has not changed for ${ago(now - mtime)} and a commit is ${ago(latest.time - mtime)} newer than it`);
    }
  }

  // Heartbeat.
  if (opts.once || state.lastBeat === null || now - state.lastBeat >= HEARTBEAT_MS) {
    state.lastBeat = now;
    const step = initText === null ? 'none' : field(initText, 'position') || 'unknown';
    let phase = 'none';
    for (const l of lines) {
      const m = l.match(/^###\s+(P[0-9]+):/);
      if (m) phase = m[1];
    }
    const last = cut([...lines].reverse().find((l) => l.trim() !== '') ?? '', MAX_TAIL);
    const since = mtime === null ? 'unknown' : ago(now - mtime);
    out(`I-C Run: heartbeat: step ${step}, phase ${phase}, last "${last}", last change ${since} ago, lock ${lockHeld ? 'held' : 'free'}`);
  }
  return false;
}

function main() {
  let opts;
  try {
    opts = parseArgs(process.argv.slice(2));
  } catch (e) {
    if (e instanceof Stop) {
      out(e.message);
      process.exit(1);
    }
    throw e;
  }
  const run = () => {
    try {
      return pass(opts);
    } catch (e) {
      if (e instanceof Stop) {
        out(e.message);
        process.exit(1);
      }
      throw e;
    }
  };
  if (opts.once) {
    for (let i = 0; i < opts.passes; i++) if (run()) break;
    process.exit(0);
  }
  if (run()) process.exit(0);
  const timer = setInterval(() => {
    if (run()) {
      clearInterval(timer);
      process.exit(0);
    }
  }, POLL_MS);
}

main();
