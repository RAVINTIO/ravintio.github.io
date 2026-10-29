import { mkdirSync, symlinkSync, realpathSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { check, makeProject, makeOutside, run, finish } from "./helpers/gate-write-harness.mjs";

console.log("\n=== REQ-006: gate-write symlink and alias cases ===");

// In-project symlink to an outside directory: real path outside, exit 0
for (const design of [false, true]) {
  const p = makeProject({ design });
  const o = makeOutside();
  symlinkSync(o, join(p, "linkout"), "dir");
  check(0, run(p, join(p, "linkout", "f.md")), `REQ-006 write through symlink to outside exits 0 (design=${design})`);
  check(0, run(p, join(p, "linkout", "new", "f.md")), `REQ-006 write through symlink to outside, missing dirs, exits 0 (design=${design})`);
}

// In-project symlink to a gated in-project dir still gets the checks
{
  const p = makeProject({ design: true });
  mkdirSync(join(p, "other"));
  symlinkSync(join(p, "other"), join(p, "alias"), "dir");
  check(2, run(p, join(p, "alias", "x.js")), "REQ-006 symlink to ungated in-project dir exits 2");
  symlinkSync(join(p, "src", "comp"), join(p, "alias2"), "dir");
  check(0, run(p, join(p, "alias2", "x.js")), "REQ-006 symlink to declared component dir exits 0");
  const pn = makeProject();
  symlinkSync(join(pn, "src"), join(pn, "alias3"), "dir");
  check(2, run(pn, join(pn, "alias3", "comp", "x.js")), "REQ-006 symlink into src with no design exits 2");
}

// Outside-looking path whose real path is inside the project: a symlinked project root
{
  const p = makeProject({ design: true });
  const o = makeOutside();
  const rootLink = join(o, "rootlink");
  symlinkSync(p, rootLink, "dir");
  check(2, run(p, join(rootLink, "other", "x.js")), "REQ-006 path via link to project root, ungated, exits 2");
  check(0, run(p, join(rootLink, "src", "comp", "x.js")), "REQ-006 path via link to project root, component, exits 0");
  check(2, run(rootLink, join(p, "other", "x.js")), "REQ-006 cwd given as symlink to project, ungated target, exits 2");
  check(0, run(rootLink, join(o, "elsewhere.md")), "REQ-006 cwd given as symlink, outside target, exits 0");
}

// Alias spellings of the same directory (macOS /tmp vs /private/tmp)
{
  const p = makeProject({ design: true });
  const real = realpathSync(p);
  check(2, run(p, join(real, "other", "x.js")), "REQ-006 real-path spelling of target, ungated, exits 2");
  check(0, run(real, join(p, "src", "comp", "x.js")), "REQ-006 cwd real spelling, target alias spelling, component, exits 0");
}

// S-002: an NFD-spelled target under an NFC project path still reads as inside
{
  const nfc = "caf\u00e9";
  const nfd = nfc.normalize("NFD");
  const base = makeOutside();
  const proj = join(base, nfc);
  mkdirSync(join(proj, "plan", "current"), { recursive: true });
  mkdirSync(join(proj, "src", "comp"), { recursive: true });
  writeFileSync(join(proj, "plan", "current", "design.md"),
    "## Component Paths\n- src/comp\n\n## Scope\n- In: test\n");
  check(2, run(proj, join(base, nfd, "other", "x.js")), "REQ-006 NFD target, NFC project, ungated, exits 2");
  check(0, run(proj, join(base, nfd, "src", "comp", "x.js")), "REQ-006 NFD target, NFC project, component, exits 0");
}
finish();
