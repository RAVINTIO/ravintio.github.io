#!/usr/bin/env node
/**
 * UserPromptSubmit hook: per-prompt orchestrator presence check.
 *
 * Two modes controlled by plan/.orchestrator-strict:
 *
 * Advisory (default):
 *   Injects a one-line banner on every prompt when a pipeline is active.
 *   Exit 0 always — never blocks.
 *
 * Strict (plan/.orchestrator-strict exists):
 *   On first prompt of a session (or after session change), injects a hard-block
 *   banner that instructs the model to load the orchestrator skill and write the
 *   session_id to plan/.orchestrator-ack before processing anything else.
 *   Once plan/.orchestrator-ack or plan/.initiative-ack contains the matching
 *   session_id, exits 0 silently.
 *   If neither matches and an initiative is active, the banner names the
 *   ravintio-initiative skill and plan/.initiative-ack instead.
 *
 * The skill that owns the session decides the banner. The driver lock plays no
 * part, because it is free between steps and after the driver exits.
 *
 * Environment: RAVINTIO_INITIATIVE_STEP=1 marks a step session started by the
 * initiative driver. The driver sets it. The hook then keeps the orchestrator
 * banner even while an initiative is active.
 *
 * Design: REQ-008.
 * Exit codes: 0 always — this hook informs but never blocks via exit 2.
 */

import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";

import { readStdin } from "./read-stdin.mjs";

// True when initiative.md holds status active, in frontmatter or as "**Status:** active".
// Keep in step with initiativeActive in auto-trigger-orchestrator.mjs.
function initiativeActive(cwd) {
  try {
    const text = readFileSync(join(cwd, "plan", "current-initiative", "initiative.md"), "utf-8");
    return /^\s*status:\s*["']?active["']?\s*$/im.test(text) ||
      /^\s*\*\*Status:\*\*\s*active\s*$/im.test(text);
  } catch {
    return false;
  }
}

try {
  const raw = await readStdin();
  const input = JSON.parse(raw);
  const cwd = input?.cwd ?? process.cwd();

  // Only act when a pipeline is active.
  const sentinelPath = join(cwd, "plan", ".orchestrator-active");
  if (!existsSync(sentinelPath)) process.exit(0);

  let featureId = "unknown";
  try {
    const raw = readFileSync(sentinelPath, "utf-8").trim();
    // Sanitise to prevent prompt injection via crafted sentinel file content.
    featureId = raw.replace(/[^a-zA-Z0-9\-_.]/g, "").slice(0, 80) || "unknown";
  } catch { /* keep default */ }

  const strictPath = join(cwd, "plan", ".orchestrator-strict");
  const isStrict = existsSync(strictPath);

  // An active initiative gives the initiative banner. A step session sets
  // RAVINTIO_INITIATIVE_STEP=1 and gets the orchestrator banner instead.
  const initiativeDriver =
    process.env.RAVINTIO_INITIATIVE_STEP !== "1" && initiativeActive(cwd);

  if (!isStrict) {
    // Advisory mode: brief banner, always passes.
    if (initiativeDriver) {
      process.stdout.write(
        `RAVINTIO PIPELINE ACTIVE [${featureId}]: ` +
        `An initiative run is in progress. ` +
        `If the ravintio-initiative skill is not currently loaded in this session ` +
        `(e.g. after context compaction or a session resume), load it now before responding.\n`
      );
      process.exit(0);
    }
    process.stdout.write(
      `RAVINTIO PIPELINE ACTIVE [${featureId}]: ` +
      `A RAVINTIO pipeline is in progress. ` +
      `If the ravintio-orchestrator skill is not currently loaded in this session ` +
      `(e.g. after context compaction or a session resume), load it now before responding. ` +
      `Begin with resume detection as described in the skill.\n`
    );
    process.exit(0);
  }

  // Strict mode: check session ack. Either ack file silences the hook.
  const sessionId = (input?.session_id ?? "").trim();
  if (sessionId) {
    for (const name of [".initiative-ack", ".orchestrator-ack"]) {
      const p = join(cwd, "plan", name);
      try {
        if (existsSync(p) && readFileSync(p, "utf-8").trim() === sessionId) process.exit(0);
      } catch { /* unreadable ack counts as no ack */ }
    }
  }

  if (initiativeDriver) {
    process.stdout.write(
      `⛔ RAVINTIO STRICT MODE [${featureId}]: ` +
      `Initiative presence is required and has not been confirmed for this session. ` +
      `STOP — do not process the user's request below. ` +
      `Load the ravintio-initiative skill now, ` +
      `then write the following session ID to plan/.initiative-ack: ${sessionId || "(session_id unavailable — write current timestamp)"}\n` +
      `Once plan/.initiative-ack is written, future prompts in this session will pass silently.\n`
    );
    process.exit(0);
  }

  // Not acked. Inject hard-block banner with session_id so the model can write the ack.
  process.stdout.write(
    `⛔ RAVINTIO STRICT MODE [${featureId}]: ` +
    `Orchestrator presence is required and has not been confirmed for this session. ` +
    `STOP — do not process the user's request below. ` +
    `Load the ravintio-orchestrator skill now, complete resume detection, ` +
    `then write the following session ID to plan/.orchestrator-ack: ${sessionId || "(session_id unavailable — write current timestamp)"}\n` +
    `Once plan/.orchestrator-ack is written, future prompts in this session will pass silently.\n`
  );

  process.exit(0);
} catch {
  process.exit(0);
}
