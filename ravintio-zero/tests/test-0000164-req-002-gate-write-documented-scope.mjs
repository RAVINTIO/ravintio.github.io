import { readFileSync } from "node:fs";
import { join } from "node:path";
import { check, makeProject, run, GATE_WRITE, finish } from "./helpers/gate-write-harness.mjs";

console.log("\n=== REQ-002: gate-write documented scope ===");

for (const dir of ["backlog", "roadmap"]) {
  const p = makeProject();
  check(0, run(p, join(p, "plan", dir, "0000166-x", "entry.md")), `REQ-002 plan/${dir}/ write with no sentinel and no design exits 0`);
  check(0, run(p, `plan/${dir}/note.md`), `REQ-002 relative plan/${dir}/ write with no sentinel and no design exits 0`);
}

const src = readFileSync(GATE_WRITE, "utf8");
const header = src.slice(0, src.indexOf("import "));
check(true, header.includes("plan/backlog/") && header.includes("plan/roadmap/"), "REQ-002 hook header names plan/backlog/ and plan/roadmap/");
check(true, /ALWAYS_PERMITTED_PREFIXES = \["plan\/", "plan\\\\", "docs\/", "docs\\\\"\];/.test(src), "REQ-002 allowed prefixes unchanged");
check(true, /"claude\.md", "agents\.md", "\.ravintio-session", "\.skips", "\.feature-id",\s+"\.gitignore", "\.gitattributes", "\.claudeignore",\s+"pause\.md",/.test(src), "REQ-002 allowed basenames unchanged");
finish();
