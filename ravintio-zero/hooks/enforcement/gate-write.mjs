#!/usr/bin/env node
/**
 * PreToolUse hook: plan compliance write gate.
 *
 * Gates this project only (0000164 ADR-002). A target whose real path lies outside
 * the project's real root passes with exit 0 before any check. Symlinks resolve first,
 * so a link inside the project that points outside counts as outside.
 *
 * Enforces these checks on in-project targets before allowing a Write or Edit (ADR-004):
 *   0. plan/current/** needs the plan/.orchestrator-active sentinel (REQ-007, ADR-003)
 *   1. Always-permitted paths (plan/, docs/, CLAUDE.md, AGENTS.md) → pass.
 *      plan/backlog/ and plan/roadmap/ fall under plan/, so they pass between runs
 *      with no sentinel and no design.md.
 *   2. design.md must exist → block with exit 2 if absent
 *   3. Target path must match a component path prefix in design.md → block if not
 *
 * Receives: JSON on stdin conforming to the RAVINTIO common envelope (ADR-002)
 * or the raw Claude Code PreToolUse hook input.
 *
 * Exit codes: 0 = pass, 2 = block (DD-004, ADR-005)
 * Silent on unexpected errors — always exit 0 on non-enforcement failures (ADR-005).
 */

import { existsSync, readFileSync, realpathSync } from "node:fs";
import { basename, dirname, join, normalize, resolve } from "node:path";

import { readStdin } from "./read-stdin.mjs";

// Always-permitted: planning/doc artefacts and RAVINTIO internal files
// plan/backlog/ and plan/roadmap/ sit under plan/ (0000164 REQ-002)
const ALWAYS_PERMITTED_PREFIXES = ["plan/", "plan\\", "docs/", "docs\\"];
const ALWAYS_PERMITTED_FILES = [
  "claude.md", "agents.md", ".ravintio-session", ".skips", ".feature-id",
  ".gitignore", ".gitattributes", ".claudeignore",
  "pause.md",
];

// Headings that introduce the component paths list in design.md (ADR-004)
const PATHS_SECTION_RE = /^##\s+(Component Paths|Scope)\s*$/im;

function norm(p) {
  return normalize(p).normalize("NFC").replace(/\\/g, "/").toLowerCase();
}

// Real path of p. If p does not exist yet, resolve the nearest existing parent
// and rejoin the remaining segments (0000164 REQ-001, ADR-002).
function realPathOrParent(p) {
  const rest = [];
  let cur = resolve(p);
  for (;;) {
    try {
      return rest.length ? join(realpathSync(cur), ...rest) : realpathSync(cur);
    } catch {
      const parent = dirname(cur);
      if (parent === cur) return resolve(p);
      rest.unshift(basename(cur));
      cur = parent;
    }
  }
}

function isAlwaysPermitted(relPath) {
  const n = norm(relPath);
  const base = n.split("/").pop() ?? "";
  if (ALWAYS_PERMITTED_FILES.includes(base)) return true;
  return ALWAYS_PERMITTED_PREFIXES.some((prefix) => n.startsWith(norm(prefix)));
}

function extractComponentPaths(content) {
  const match = PATHS_SECTION_RE.exec(content);
  if (!match) return null;

  const afterHeading = content.slice(match.index + match[0].length);
  const lines = afterHeading.split("\n");
  const paths = [];

  for (const line of lines) {
    if (/^##\s/.test(line)) break; // stop at next h2
    // Match: "- path", "* path", "- `path`", "| path |" table rows
    const m = line.match(/^[\s*\-|]+`?([^\s`|,{}]+)`?/);
    if (m?.[1] && !m[1].startsWith("{") && m[1].includes("/")) {
      paths.push(m[1].replace(/\/$/, "")); // strip trailing slash for normalised comparison
    }
  }

  return paths.length ? paths : null;
}

function matchesComponentPath(relPath, componentPaths) {
  const normTarget = norm(relPath);
  return componentPaths.some((cp) => {
    const normCp = norm(cp);
    // prefix match: target starts with component path (with separator)
    return normTarget === normCp || normTarget.startsWith(normCp + "/");
  });
}

// Claude Code shows the agent only stderr on exit 2. Stdout keeps the tests' view.
function block(message) {
  message = message.replace(/\n$/, "") + " See ravintio-zero/standards/hook-enforcement.md.\n";
  process.stderr.write(message);
  process.stdout.write(message);
  process.exit(2);
}

try {
  const raw = await readStdin();
  const input = JSON.parse(raw);

  // Support both common envelope (ADR-002) and raw Claude Code hook input
  const cwd = input?.cwd ?? process.cwd();
  const toolInput = input?.tool_input ?? input;
  const rawTarget = toolInput?.path ?? toolInput?.file_path ?? "";

  // No target path = pass (not a file-writing tool call)
  if (!rawTarget) process.exit(0);

  // Resolve to a path relative to cwd for prefix matching.
  // Normalise both paths to forward-slash form before comparison to avoid
  // mixed-separator failures on Windows (ADR-005, REQ-012).
  // Both sides resolve through realpath so symlinks and /tmp aliases compare true
  // (0000164 REQ-001, REQ-006, ADR-002).
  const absTarget = realPathOrParent(resolve(cwd, rawTarget));
  const normCwd = norm(realPathOrParent(cwd));
  const normAbs = norm(absTarget);
  const cwdPrefix = normCwd.endsWith("/") ? normCwd : normCwd + "/";

  // Outside the project's real root → not this hook's business (ADR-002).
  if (normAbs !== normCwd && !normAbs.startsWith(cwdPrefix)) process.exit(0);

  const relTarget = normAbs === normCwd ? "" : normAbs.slice(cwdPrefix.length);

  // Check 0 — sentinel enforcement for plan/current/** (REQ-007, ADR-003)
  // feature-brief.md and ALWAYS_PERMITTED_FILES (e.g. pause.md) bypass sentinel so
  // P0 can begin and pause/resume works at any pipeline phase.
  const normRel = norm(relTarget);
  const isPlanCurrent = normRel.startsWith("plan/current/") || normRel === "plan/current";
  const isFeatureBrief = normRel.endsWith("feature-brief.md");
  const isAlwaysPermittedBasename = ALWAYS_PERMITTED_FILES.includes(basename(relTarget));
  if (isPlanCurrent && !isFeatureBrief && !isAlwaysPermittedBasename) {
    const sentinelPath = join(cwd, "plan", ".orchestrator-active");
    if (!existsSync(sentinelPath)) {
      block(
        "[RAVINTIO] No orchestrator sentinel at plan/.orchestrator-active. " +
        "Load the ravintio-orchestrator skill and complete P0 Discovery before " +
        "writing plan artefacts.\n"
      );
    }
  }

  // Check 1 — always-permitted paths (ADR-004)
  if (isAlwaysPermitted(relTarget)) process.exit(0);

  // Check 2 — design.md must exist
  const designPath = join(cwd, "plan", "current", "design.md");
  if (!existsSync(designPath)) {
    block(
      "[RAVINTIO] No confirmed design at plan/current/design.md. " +
      "Complete P0 Discovery first.\n"
    );
  }

  // Check 3 — path must be in component paths list
  let designContent;
  try {
    designContent = readFileSync(designPath, "utf-8");
  } catch {
    process.exit(0); // Can't read design → pass through (ADR-005)
  }

  const componentPaths = extractComponentPaths(designContent);
  if (!componentPaths) {
    // Section missing or unparseable → warn but pass through (ADR-005, R-006)
    process.stderr.write(
      "[RAVINTIO] Warning: Could not parse component paths from " +
      "plan/current/design.md. Ensure a '## Component Paths' section exists. " +
      "Write allowed.\n"
    );
    process.exit(0);
  }

  if (!matchesComponentPath(relTarget, componentPaths)) {
    block(
      `[RAVINTIO] Path '${relTarget}' is not covered by the confirmed design. ` +
      "Add it to the '## Component Paths' section of plan/current/design.md first.\n"
    );
  }

  process.exit(0);
} catch {
  // Never block the session on unexpected errors (ADR-005).
  process.exit(0);
}
