#!/usr/bin/env node
/**
 * PreToolUse hook (matcher: Bash): merge guard (feature 0000043, ADR-003).
 *
 * Fail-closed design. Step 1 is a raw-text tripwire on the whole command,
 * applied before any parsing and whatever the length. It trips on:
 *   - `pr` then whitespace then `merge`, as words, anywhere
 *   - a GitHub API merge path (`pulls/<n>/merge`)
 *   - `gh` and `api` and `merge` in one command
 * A command that trips the wire passes only if the strict parser finds
 * exactly one plain `gh pr merge` call that:
 *   1. has `gh` as a bare word in command position, with no quoting,
 *      substitution, variable, wrapper, or alias in its segment
 *   2. uses --squash (and no --merge, --rebase, or --admin)
 *   3. names at most one PR selector
 *   4. targets a PR whose base, read by `gh pr view`, starts with initiative/
 * Anything else that trips the wire is blocked, including commands over
 * 4096 characters. Commands that do not trip the wire pass.
 *
 * The hook never runs, evaluates, or shells out the command text.
 * Out of scope: `git push` to main. Branch protection covers it.
 *
 * Exit codes: 0 = pass, 2 = block (message on stdout).
 * Malformed stdin and non-Bash tools exit 0, because no command text exists.
 */

import { spawnSync } from "node:child_process";

import { readStdin } from "./read-stdin.mjs";

const MAX_COMMAND = 4096;
// Text that names a merge is blocked wherever it sits, so a file write needs the Write tool.
const WRITE_ADVICE = "To write a file, use the Write tool, not a shell command.";
const PR_merge_RE = /\bpr\s+merge\b/;
const API_PATH_RE = /pulls\/[^\s/]*\/merge/;
const GH_RE = /\bgh\b/;
const API_RE = /\bapi\b/;
const merge_RE = /merge/;
// Characters that make a segment more than plain words.
const UNPLAIN_RE = /["'`$\\(){}<>*?~!#=\[\]]/;
// Flags that take a value, so the value is not mistaken for the PR selector.
const VALUE_FLAGS = new Set([
  "-b", "--body", "-F", "--body-file", "-t", "--subject",
  "-A", "--author-email", "--match-head-commit", "-R", "--repo",
]);
const REPO_FLAGS = new Set(["-R", "--repo"]);
const SAFE_REF = /[^a-zA-Z0-9\-_./#:]/g;

function block(reason) {
  const message =
    "[RAVINTIO] merge-guard: Merge blocked. Merges into main are human-only. " +
    "The agent may squash-merge only into initiative/*. " + reason +
    " See ravintio-zero/standards/hook-enforcement.md.\n";
  // Claude Code shows the agent stderr on exit 2. Stdout keeps the tests' view.
  process.stderr.write(message);
  process.stdout.write(message);
  process.exit(2);
}

function unconfirmed(detail) {
  block(`Cannot confirm the merge is a squash into initiative/*. ${detail}`);
}

function trips(command) {
  return (
    PR_merge_RE.test(command) ||
    API_PATH_RE.test(command) ||
    (GH_RE.test(command) && API_RE.test(command) && merge_RE.test(command))
  );
}

// Returns the parsed call, or null if the segment is not a plain gh pr merge.
// The reason for a rejection goes in `why[0]`.
function parsePlain(segment, why) {
  const text = segment.trim();
  if (UNPLAIN_RE.test(text)) {
    // Allow `=` only inside a --flag=value token.
    const stripped = text.replace(
      /(^|\s)--?[A-Za-z][\w-]*=[^\s"'`$\\(){}<>*?~!#=\[\]]*/g, " ");
    if (UNPLAIN_RE.test(stripped)) {
      why[0] = "The segment uses quoting, substitution, or a variable. " + WRITE_ADVICE;
      return null;
    }
  }
  const tokens = text.split(/\s+/);
  if (tokens[0] !== "gh" || tokens[1] !== "pr" || tokens[2] !== "merge") {
    why[0] = "The command names a merge in text that isn't a merge call. " + WRITE_ADVICE;
    return null;
  }
  const flags = new Map();
  const positional = [];
  let repo = "";
  let repoCount = 0;
  for (let i = 3; i < tokens.length; i++) {
    const t = tokens[i];
    if (/^-[A-Za-z]{2,}$/.test(t)) {
      why[0] = "Combined short flags are not accepted.";
      return null;
    }
    if (t.startsWith("-")) {
      const eq = t.indexOf("=");
      const name = eq < 0 ? t : t.slice(0, eq);
      const value = eq < 0 ? null : t.slice(eq + 1);
      if (REPO_FLAGS.has(name)) {
        repoCount++;
        repo = value !== null ? value : (tokens[++i] ?? "");
      } else if (VALUE_FLAGS.has(name) && value === null) {
        i++;
      }
      flags.set(name, value);
    } else {
      positional.push(t);
    }
  }
  if (repoCount > 1) {
    why[0] = "The repository flag appears more than once.";
    return null;
  }
  if (positional.length > 1) {
    why[0] = "More than one PR selector was given.";
    return null;
  }
  const ref = positional[0] ?? "";
  if (ref.replace(SAFE_REF, "") !== ref || repo.replace(SAFE_REF, "") !== repo) {
    why[0] = "The PR selector holds unsafe characters.";
    return null;
  }
  return { flags, ref, repo };
}

function checkFlags(flags) {
  if (!flags.has("--squash") && !flags.has("-s")) return "Pass --squash.";
  const value = flags.get("--squash");
  if (flags.has("--squash") && value !== null && value !== "true") {
    return "The --squash flag has a value other than true.";
  }
  for (const bad of ["--merge", "-m", "--rebase", "-r", "--admin"]) {
    if (flags.has(bad)) return `The ${bad} flag is not allowed.`;
  }
  return "";
}

function readBase({ ref, repo }) {
  const args = ["pr", "view"];
  if (ref) args.push(ref);
  if (repo) args.push("--repo", repo);
  args.push("--json", "baseRefName");
  const r = spawnSync("gh", args, { encoding: "utf-8", timeout: 30000 });
  if (r.error || r.status !== 0) return "";
  try {
    return String(JSON.parse(r.stdout).baseRefName ?? "").replace(SAFE_REF, "");
  } catch {
    return "";
  }
}

function evaluate(command) {
  if (command.length > MAX_COMMAND) {
    unconfirmed("The command is over 4096 characters. " + WRITE_ADVICE);
  }
  const segments = command.split(/&&|\|\||[;&|\n]/);
  const calls = [];
  for (const segment of segments) {
    if (!PR_merge_RE.test(segment) && !merge_RE.test(segment) && !API_RE.test(segment)) {
      continue;
    }
    const why = [""];
    const parsed = parsePlain(segment, why);
    if (!parsed) unconfirmed(why[0]);
    calls.push(parsed);
  }
  if (calls.length !== 1) {
    unconfirmed(`The command holds ${calls.length} plain merge calls, not one.`);
  }
  const parsed = calls[0];
  const flagProblem = checkFlags(parsed.flags);
  if (flagProblem) block(flagProblem);
  const base = readBase(parsed);
  if (!base) block("The PR base could not be read, so the merge is blocked.");
  if (!base.startsWith("initiative/")) block(`The PR base is '${base}'.`);
}

let command = "";
try {
  const input = JSON.parse(await readStdin());
  const tool = input?.tool_name;
  if (tool && tool !== "Bash") process.exit(0);
  command = String(input?.tool_input?.command ?? "");
} catch {
  process.exit(0);
}

if (!trips(command)) process.exit(0);

try {
  evaluate(command);
  process.exit(0);
} catch {
  // The wire tripped, so an unexpected error fails closed.
  unconfirmed("The guard hit an unexpected error.");
}
