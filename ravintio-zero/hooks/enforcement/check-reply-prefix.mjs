#!/usr/bin/env node
/**
 * Stop hook: reply prefix check (feature 0000200, REQ-003, ADR-002).
 *
 * Checks that the last assistant reply in an active run starts with a valid
 * phase or stage prefix. A miss warns the human and adds one line to the miss
 * log, so the human can measure how often the rule fails.
 *
 * Valid prefixes: P0 Discovery:, P1 Plan:, P2 Implement:, P3 Validate:,
 * P4 Ship:, I-A Chart:, I-B Activate:, I-C Run:, I-D Advance:, I-E Delivery:,
 * and Supervise:. The phase name "Validate and Accept" is not valid.
 *
 * Receives: JSON on stdin (Claude Code Stop payload). The hook reads
 * transcript_path (a JSONL file) and takes the text of the last assistant
 * message. Content may be a string or an array of { type: "text", text }
 * blocks. The hook checks the first non-empty line of that text.
 *
 * Outputs: JSON { systemMessage: "<string>" } on stdout for a miss, or
 * nothing otherwise. A miss also appends "<ISO timestamp> <first 80
 * characters of the reply>" to plan/.prefix-misses.log under payload.cwd
 * (else process.cwd()).
 *
 * Skips silently when plan/.orchestrator-active is absent.
 *
 * Always exits 0. The hook warns and never blocks a turn (ADR-002).
 */

import { appendFileSync, existsSync, readFileSync } from "node:fs";
import { join } from "node:path";

import { readStdin } from "./read-stdin.mjs";

const VALID_PREFIXES = [
  "P0 Discovery:",
  "P1 Plan:",
  "P2 Implement:",
  "P3 Validate:",
  "P4 Ship:",
  "I-A Chart:",
  "I-B Activate:",
  "I-C Run:",
  "I-D Advance:",
  "I-E Delivery:",
  "Supervise:",
];

const LOG_SNIPPET_LENGTH = 80;

function textOf(content) {
  if (typeof content === "string") return content;
  if (Array.isArray(content)) {
    return content
      .filter((b) => b && b.type === "text" && typeof b.text === "string")
      .map((b) => b.text)
      .join("\n");
  }
  return "";
}

function lastAssistantText(transcript) {
  const lines = transcript.split("\n");
  for (let i = lines.length - 1; i >= 0; i--) {
    if (!lines[i].trim()) continue;
    let entry;
    try {
      entry = JSON.parse(lines[i]);
    } catch {
      continue;
    }
    const message = entry?.message ?? entry;
    const role = message?.role ?? entry?.type;
    if (role !== "assistant") continue;
    const text = textOf(message?.content);
    if (text.trim()) return text;
  }
  return null;
}

try {
  const raw = await readStdin();
  const input = JSON.parse(raw);
  const cwd = input?.cwd ?? process.cwd();

  if (!existsSync(join(cwd, "plan", ".orchestrator-active"))) process.exit(0);

  const transcriptPath = input?.transcript_path;
  if (typeof transcriptPath !== "string" || !existsSync(transcriptPath)) process.exit(0);

  const reply = lastAssistantText(readFileSync(transcriptPath, "utf-8"));
  if (reply === null) process.exit(0);

  const firstLine = reply.split("\n").find((l) => l.trim() !== "") ?? "";
  if (VALID_PREFIXES.some((p) => firstLine.trimStart().startsWith(p))) process.exit(0);

  const snippet = reply.trim().replace(/\s+/g, " ").slice(0, LOG_SNIPPET_LENGTH);
  try {
    // Keep the log out of git. Add it to .git/info/exclude once.
    const excludePath = join(cwd, ".git", "info", "exclude");
    if (existsSync(join(cwd, ".git", "info"))) {
      const held = existsSync(excludePath) ? readFileSync(excludePath, "utf-8") : "";
      if (!held.split("\n").includes("plan/.prefix-misses.log")) {
        appendFileSync(excludePath, (held === "" || held.endsWith("\n") ? "" : "\n") + "plan/.prefix-misses.log\n");
      }
    }
    appendFileSync(
      join(cwd, "plan", ".prefix-misses.log"),
      `${new Date().toISOString()} ${snippet}\n`,
    );
  } catch {
    // A log failure must not stop the warning.
  }

  const systemMessage =
    "[RAVINTIO] Reply is missing a valid prefix. Start every reply in an active run with " +
    "one of: " + VALID_PREFIXES.join(" ") + " The miss is logged to plan/.prefix-misses.log.";
  process.stdout.write(JSON.stringify({ systemMessage }));
  process.exit(0);
} catch {
  // Stop must never block a turn. Silent fallback (ADR-002).
  process.exit(0);
}
