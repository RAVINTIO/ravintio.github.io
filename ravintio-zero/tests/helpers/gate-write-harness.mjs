/**
 * Shared harness for the 0000164 gate-write tests.
 * Builds temporary projects with mkdtemp outside the repo and runs the hook.
 */
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { join, dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";
import os from "node:os";

const here = dirname(fileURLToPath(import.meta.url));
export const GATE_WRITE = resolve(here, "../../hooks/enforcement/gate-write.mjs");

export const ROOT = mkdtempSync(join(os.tmpdir(), "ravintio-gw164-"));
process.on("exit", () => {
  try { rmSync(ROOT, { recursive: true, force: true }); } catch {}
});

let PASS = 0;
let FAIL = 0;
let n = 0;

export function check(expected, actual, label) {
  if (String(expected) === String(actual)) {
    console.log(`  PASS: ${label}`);
    PASS++;
  } else {
    console.log(`  FAIL: ${label}\n        expected: ${expected}\n        actual:   ${actual}`);
    FAIL++;
  }
}

export function makeProject({ design = false, sentinel = false } = {}) {
  const dir = join(ROOT, `p${++n}`, "proj");
  mkdirSync(join(dir, "plan", "current"), { recursive: true });
  mkdirSync(join(dir, "src", "comp"), { recursive: true });
  if (sentinel) writeFileSync(join(dir, "plan", ".orchestrator-active"), "");
  if (design) {
    writeFileSync(join(dir, "plan", "current", "design.md"),
      "## Component Paths\n- src/comp\n\n## Scope\n- In: test\n");
  }
  return dir;
}

export function makeOutside() {
  const dir = join(ROOT, `o${++n}`);
  mkdirSync(dir, { recursive: true });
  return dir;
}

export function run(cwd, target) {
  const r = spawnSync("node", [GATE_WRITE], {
    input: JSON.stringify({ cwd, tool_input: { file_path: target } }),
    encoding: "utf8",
  });
  return r.status ?? 1;
}

export function finish() {
  console.log(`\nPassed: ${PASS}  Failed: ${FAIL}`);
  process.exit(FAIL === 0 ? 0 : 1);
}
