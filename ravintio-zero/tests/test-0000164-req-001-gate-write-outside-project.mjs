import { writeFileSync } from "node:fs";
import { join } from "node:path";
import { check, makeProject, makeOutside, run, finish } from "./helpers/gate-write-harness.mjs";

console.log("\n=== REQ-001: gate-write passes targets outside the project ===");

for (const design of [false, true]) {
  const p = makeProject({ design });
  const o = makeOutside();
  const tag = design ? "with design" : "no design";
  check(0, run(p, join(o, "memory.md")), `REQ-001 outside absolute target exits 0 (${tag})`);
  check(0, run(p, join(o, "new", "deep", "f.txt")), `REQ-001 outside target in missing dirs exits 0 (${tag})`);
  check(0, run(p, "../../elsewhere/x.md"), `REQ-001 outside relative target exits 0 (${tag})`);
}

const p = makeProject({ design: true });
check(2, run(p, join(p, "other", "x.js")), "REQ-001 in-project target outside component paths exits 2");
check(0, run(p, join(p, "src", "comp", "a.js")), "REQ-001 in-project component target exits 0");
check(2, run(p, join(p, "plan", "current", "x.md")), "REQ-001 plan/current without sentinel exits 2");
const ps = makeProject({ design: true, sentinel: true });
check(0, run(ps, join(ps, "plan", "current", "x.md")), "REQ-001 plan/current with sentinel exits 0");
const pn = makeProject();
check(2, run(pn, join(pn, "src", "comp", "a.js")), "REQ-001 in-project src target with no design exits 2");
finish();
