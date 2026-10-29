/**
 * Shared hook helper: read the JSON payload a hook receives on stdin.
 *
 * Extracted from the per-hook copies that previously lived one per hook, so
 * every hook reads stdin the same way.
 *
 * PLACEMENT: this module lives in hooks/enforcement/, beside the six
 * enforcement hooks that import it. Setup installs that directory as a unit,
 * so a hook never resolves this import against an absent file. A missing
 * import fails at ESM module-load time, before the hook's own top-level
 * try/catch can run, which would break the exit-zero-on-every-path invariant
 * instead of degrading gracefully.
 *
 * DELIBERATE BEHAVIOUR: this shared copy always wires
 * process.stdin.on("error", reject). Most of the earlier per-hook copies wired
 * "data" and "end" but no "error" handler, so a stdin stream error left the
 * returned promise unsettled forever and the hook stalled rather than exiting
 * 0. That stall violates NFR-001, which says a hook must never block the
 * session. Every caller awaits readStdin() inside a top-level try/catch (or,
 * for ratchet-check.mjs, main().catch(...)) that exits 0, so rejecting here
 * converts an indefinite stall into the caller's existing fail-open path.
 *
 * The BOM strip is unchanged. The prior copies expressed it as either
 * /^﻿/ or a literal U+FEFF inside the regex literal; those are the same
 * regular expression, so no caller's parsing behaviour changes.
 */

export function readStdin() {
  return new Promise((resolve, reject) => {
    let data = "";
    process.stdin.setEncoding("utf-8");
    process.stdin.on("data", (chunk) => { data += chunk; });
    process.stdin.on("end", () => resolve(data.replace(/^﻿/, "")));
    process.stdin.on("error", reject);
    process.stdin.resume();
  });
}
