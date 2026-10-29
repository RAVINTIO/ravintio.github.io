#!/usr/bin/env node
/**
 * UserPromptSubmit hook: auto-trigger the ravintio-orchestrator skill.
 *
 * Fires on every user prompt. Performs two fast file-existence checks:
 *   1. ravintio-zero/ exists → this is a ravintio project
 *   2. plan/.orchestrator-active does NOT exist → orchestrator not yet loaded
 *
 * If both conditions are met, outputs an instruction to the model to load
 * the ravintio-orchestrator skill. The instruction appears inline in the
 * model's context before it processes the user prompt.
 *
 * If either condition fails, exits 0 silently (no output, no effect).
 *
 * Initiative case: if plan/current-initiative/initiative.md holds status active
 * and plan/.orchestrator-active is absent, the instruction names the
 * ravintio-initiative skill instead. The driver lock (plan/.initiative-runner.lock)
 * and the contents of plan/current/ play no part. The strict-mode hook
 * (check-orchestrator-presence.mjs) applies the same rule.
 *
 * Resume findings: both instructions end with the lines that
 * ravintio-zero/scripts/resume-detect.mjs prints (0000243). A run that fails or
 * passes 2 seconds adds "resume detection did not run" instead.
 *
 * Environment: RAVINTIO_INITIATIVE_STEP=1 marks a step session started by the
 * initiative driver (`claude -p "Run initiative step N"`). A step session looks
 * the same as a human session, so the driver sets this variable. When it is
 * set, the hook keeps the orchestrator instruction.
 *
 * Design: ADR-003 — auto-trigger via UserPromptSubmit + CLAUDE.md fallback.
 * REQ-002.
 *
 * Exit codes: 0 = pass (no action or instruction emitted)
 * Never exits 2 — this hook does not block user prompts.
 */

import { spawnSync } from "node:child_process";
import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";

import { readStdin } from "./read-stdin.mjs";

// True when initiative.md holds status active, in frontmatter or as "**Status:** active".
// Keep in step with initiativeActive in check-orchestrator-presence.mjs.
function initiativeActive(cwd) {
  try {
    const text = readFileSync(join(cwd, "plan", "current-initiative", "initiative.md"), "utf-8");
    return /^\s*status:\s*["']?active["']?\s*$/im.test(text) ||
      /^\s*\*\*Status:\*\*\s*active\s*$/im.test(text);
  } catch {
    return false;
  }
}

// Resume findings: fixed lines from resume-detect.mjs, run with a 2 second timeout.
// A missing script, a non-zero exit, or a timeout gives the failure line, so a
// failed run never reads as "no resume signals". The script prints no repo text.
function resumeFindings(cwd) {
  const failed = "Resume findings: resume detection did not run\n";
  try {
    const script = join(cwd, "ravintio-zero", "scripts", "resume-detect.mjs");
    if (!existsSync(script)) return failed;
    const run = spawnSync(process.execPath, [script, cwd], {
      encoding: "utf-8",
      timeout: 2000,
      env: process.env,
    });
    if (run.error || run.status !== 0 || !run.stdout.trim()) return failed;
    const lines = run.stdout.trim().split("\n").map((l) => `- ${l}`).join("\n");
    return `Resume findings (fixed text from resume-detect.mjs, act on them in order):\n${lines}\n`;
  } catch {
    return failed;
  }
}

try {
  const raw = await readStdin();
  const input = JSON.parse(raw);
  const cwd = input?.cwd ?? process.cwd();

  // Check 1 — is this a ravintio project?
  const zeroDir = join(cwd, "ravintio-zero");
  if (!existsSync(zeroDir)) process.exit(0);

  // Check 2 — is the orchestrator already active?
  const sentinelPath = join(cwd, "plan", ".orchestrator-active");
  if (existsSync(sentinelPath)) process.exit(0);

  // Initiative check: an active initiative means the session drives it. A step
  // session sets RAVINTIO_INITIATIVE_STEP=1 and keeps the orchestrator. Neither
  // the driver lock nor plan/current/ is read.
  if (process.env.RAVINTIO_INITIATIVE_STEP !== "1" && initiativeActive(cwd)) {
    process.stdout.write(
      "SYSTEM INSTRUCTION: This is a RAVINTIO project (ravintio-zero/ detected) " +
      "with an active initiative (plan/current-initiative/initiative.md). " +
      "Load the ravintio-initiative skill now, before responding to the user's prompt. " +
      "Begin with resume detection as described in the skill.\n" +
      resumeFindings(cwd)
    );
    process.exit(0);
  }

  // Both conditions met: emit the instruction to load the orchestrator.
  // Claude Code injects this output into the model's context before the prompt.
  process.stdout.write(
    "SYSTEM INSTRUCTION: This is a RAVINTIO project (ravintio-zero/ detected) " +
    "and the orchestrator has not been loaded yet for this session. " +
    "Load the ravintio-orchestrator skill now, before responding to the user's prompt. " +
    "Begin with resume detection as described in the skill.\n" +
    resumeFindings(cwd)
  );

  process.exit(0);
} catch {
  // Never interfere with the session on unexpected errors.
  process.exit(0);
}
