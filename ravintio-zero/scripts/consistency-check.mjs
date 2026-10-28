#!/usr/bin/env node
/**
 * consistency-check.mjs — deterministic cross-artifact consistency validation
 * over plan/current/ (REQ-014, feature 0000016). The cheapest verifier layer:
 * pure file parsing, no model, no network. Run standalone or from the
 * ravintio-design-critic skill.
 *
 * Usage: node consistency-check.mjs [planCurrentDir]   (default: plan/current)
 *
 * Checks:
 *   1. Story traceability — every requirement file names a Source user story
 *   2. Acceptance criteria — no requirement exceeds 3 criteria in its
 *      "## Acceptance Criteria" section
 *   3. ADR references — every ADR-NNN referenced anywhere resolves to a file
 *      in adr/
 *   4. Risk mitigations — every R-NNN row in risk-register.md has a non-empty
 *      Mitigation column
 *   5. Design scope — design.md declares a Scope (or Component Paths) section
 *      so gate-write has component paths to enforce
 *   6. Gherkin criteria (feature 0000170, ADR-003) — each checkbox criterion in
 *      "## Acceptance Criteria" holds indented Given, When, and Then step lines
 *      in that order. And and But continue any step. A finding names the file
 *      and the criterion's AC-n, or its line number if it has no AC-n.
 *   7. Story map (feature 0000170) — when requirement files exist, plan/current/
 *      story-map.md exists, every requirement Source US-nnn appears in it, and
 *      every Backbone row has a Requirement cell. The cell names a REQ-nnn that
 *      has a req-nnn-*.md file, or reads "gap: {disposition}".
 *   8. Concurrency plan (feature 0000201, ADR-002) — when execution-plan.md
 *      exists, it holds a "## Concurrency plan" table with the columns Unit,
 *      Depends on, Writes, Batch, and Sequential reason, and at least one unit
 *      row. Each Batch is a positive whole number. A unit alone in its batch
 *      has a Sequential reason. Two units in one batch share no Writes path.
 *      Each Depends on names a unit in an earlier batch. A missing
 *      execution-plan.md skips the check.
 *
 * A finding that echoes a story map row label prints at most 200 characters of
 * it, with a trailing marker if it cut the label (feature 0000198).
 *
 * Exit codes: 0 = clean, 1 = findings (listed on stdout).
 */

import { existsSync, readFileSync, readdirSync } from "node:fs";
import { join } from "node:path";

const dir = process.argv[2] ?? join(process.cwd(), "plan", "current");
const findings = [];

function read(p) {
  try { return readFileSync(p, "utf-8"); } catch { return null; }
}

/** Cuts an echoed plan line to 200 code points and marks the cut (feature 0000198). */
function cap(line) {
  const chars = Array.from(line);
  if (chars.length <= 200) return line;
  return chars.slice(0, 200).join("") + " …[truncated]";
}

function section(text, heading) {
  // Returns the body of "## {heading}" up to the next "## " heading.
  const re = new RegExp(`^##\\s+${heading}\\s*$`, "im");
  const m = re.exec(text);
  if (!m) return null;
  const rest = text.slice(m.index + m[0].length);
  const next = rest.search(/^##\s+/m);
  return next === -1 ? rest : rest.slice(0, next);
}

if (!existsSync(dir)) {
  console.error(`consistency-check: no such directory: ${dir}`);
  process.exit(1);
}

/** Gherkin check (check 6): one finding per malformed criterion. */
function checkGherkin(file, text, ac) {
  const base = text.slice(0, text.indexOf(ac)).split(/\r?\n/).length - 1;
  const lines = ac.split(/\r?\n/);
  let cur = null;
  const crits = [];
  lines.forEach((line, i) => {
    if (/^\s*-\s*\[[ x]\]/i.test(line)) {
      cur = { id: line.match(/\bAC-\d+/)?.[0] ?? `line ${base + i + 1}`, steps: [] };
      crits.push(cur);
      return;
    }
    const step = line.match(/^\s+-\s*(Given|When|Then|And|But)\b/);
    if (cur && step) cur.steps.push(step[1]);
  });
  for (const { id, steps } of crits) {
    const g = steps.indexOf("Given");
    const w = steps.indexOf("When");
    const t = steps.indexOf("Then");
    const missing = [["Given", g], ["When", w], ["Then", t]].filter(([, i]) => i === -1).map(([n]) => n);
    if (missing.length > 0) {
      findings.push(`${file}: ${id} has no ${missing.join(", ")} step (Gherkin: Given, When, Then)`);
    } else if (!(g < w && w < t)) {
      findings.push(`${file}: ${id} steps are out of order (Gherkin: Given, When, Then)`);
    }
  }
}

// ---- 1 + 2: requirement files --------------------------------------------
const reqDir = join(dir, "requirements");
const reqFiles = existsSync(reqDir)
  ? readdirSync(reqDir).filter((f) => f.endsWith(".md"))
  : [];

for (const f of reqFiles) {
  const text = read(join(reqDir, f)) ?? "";

  // 1. story traceability
  if (!/\*\*Source:\*\*\s*US-\d+/.test(text)) {
    findings.push(`${f}: no Source user story (US-nnn) — story↔requirement traceability broken`);
  }

  // 2. ≤3 acceptance criteria (counted inside the AC section only)
  const ac = section(text, "Acceptance Criteria");
  if (ac !== null) {
    const count = (ac.match(/^\s*-\s*\[[ x]\]/gim) ?? []).length;
    if (count > 3) {
      findings.push(`${f}: ${count} acceptance criteria (max 3 per requirement — split the story)`);
    }
    checkGherkin(f, text, ac);
  }
}

// ---- 7: story map (feature 0000170) -----------------------------------------
if (reqFiles.length > 0) {
  const mapText = read(join(dir, "story-map.md"));
  if (mapText === null) {
    findings.push("story-map.md: missing — requirement files exist but no story map maps them");
  } else {
    for (const f of reqFiles) {
      const us = (read(join(reqDir, f)) ?? "").match(/\*\*Source:\*\*\s*(US-\d+)/)?.[1];
      if (us && !new RegExp(`\\b${us}\\b`).test(mapText)) {
        findings.push(`story-map.md: ${us} (Source of ${f}) does not appear in the story map`);
      }
    }
    let col = -1;
    for (const line of mapText.split(/\r?\n/)) {
      if (!line.trim().startsWith("|")) continue;
      const cells = line.trim().replace(/^\||\|$/g, "").split("|").map((c) => c.trim());
      if (cells.some((c) => /^-+:?$|^:-+:?$/.test(c))) continue; // separator row
      if (cells.some((c) => c.toLowerCase() === "requirement")) {
        col = cells.findIndex((c) => c.toLowerCase() === "requirement");
        continue;
      }
      if (col === -1) continue;
      const label = cap(cells[1] || cells[0] || "(unnamed row)");
      const cell = cells[col] ?? "";
      if (cell === "") {
        findings.push(`story-map.md: row "${label}" has an empty Requirement cell`);
        continue;
      }
      for (const ref of new Set(cell.match(/REQ-\d+/g) ?? [])) {
        const prefix = `${ref.toLowerCase()}-`;
        if (!reqFiles.some((f) => f.startsWith(prefix))) {
          findings.push(`story-map.md: row "${label}" names ${ref} but no ${prefix}*.md file exists`);
        }
      }
    }
  }
}

// ---- 8: concurrency plan (feature 0000201, ADR-002) --------------------------
const planText = read(join(dir, "execution-plan.md"));
if (planText !== null) {
  const body = section(planText, "Concurrency plan");
  const cols = ["unit", "depends on", "writes", "batch", "sequential reason"];
  const list = (c) => c.replace(/`/g, "").split(",").map((s) => s.trim())
    .filter((s) => s !== "" && s.toLowerCase() !== "none" && s !== "-");
  const units = [];
  let idx = null;
  if (body === null) {
    findings.push("execution-plan.md: no '## Concurrency plan' section — plan has no batches");
  } else {
    for (const line of body.split(/\r?\n/)) {
      if (!line.trim().startsWith("|")) continue;
      const cells = line.trim().replace(/^\||\|$/g, "").split("|").map((c) => c.trim());
      if (cells.every((c) => /^:?-{3,}:?$/.test(c))) continue; // separator row, a lone "-" is data
      if (idx === null) {
        const found = cols.map((n) => cells.findIndex((c) => c.toLowerCase() === n));
        if (found.every((i) => i !== -1)) idx = found;
        continue;
      }
      units.push({
        name: cells[idx[0]] ?? "",
        deps: list(cells[idx[1]] ?? ""),
        writes: list(cells[idx[2]] ?? ""),
        batchRaw: (cells[idx[3]] ?? "").replace(/`/g, "").trim(),
        reason: (cells[idx[4]] ?? "").replace(/`/g, "").trim(),
      });
    }
    if (idx === null) {
      findings.push("execution-plan.md: Concurrency plan has no table with the columns Unit, Depends on, Writes, Batch, Sequential reason");
    } else if (units.length === 0) {
      findings.push("execution-plan.md: Concurrency plan table has no unit row");
    }
  }
  for (const u of units) {
    u.label = cap(u.name || "(unnamed unit)");
    u.batch = /^[1-9]\d*$/.test(u.batchRaw) ? Number(u.batchRaw) : null;
    if (u.batch === null) {
      findings.push(`execution-plan.md: unit ${u.label} has Batch "${cap(u.batchRaw)}", not a positive whole number`);
    }
  }
  const byName = new Map(units.map((u) => [u.name, u]));
  for (const u of units) {
    if (u.batch === null) continue;
    const mates = units.filter((o) => o !== u && o.batch === u.batch);
    if (mates.length === 0 && ["", "none", "-"].includes(u.reason.toLowerCase())) {
      findings.push(`execution-plan.md: unit ${u.label} is alone in batch ${u.batch} with no Sequential reason`);
    }
    for (const dep of u.deps) {
      const target = byName.get(dep);
      if (!target) {
        findings.push(`execution-plan.md: unit ${u.label} depends on ${cap(dep)}, which is not a unit in the table`);
      } else if (target.batch !== null && target.batch >= u.batch) {
        findings.push(`execution-plan.md: unit ${u.label} depends on ${cap(dep)}, which is in batch ${target.batch}, not an earlier batch than ${u.batch}`);
      }
    }
    for (const o of mates) {
      if (units.indexOf(o) < units.indexOf(u)) continue; // report each pair once
      for (const p of u.writes.filter((w) => o.writes.includes(w))) {
        findings.push(`execution-plan.md: units ${u.label} and ${cap(o.name)} both write ${cap(p)} in batch ${u.batch}`);
      }
    }
  }
}

// ---- 3: orphaned ADR references -------------------------------------------
const adrDir = join(dir, "adr");
const adrIds = new Set(
  (existsSync(adrDir) ? readdirSync(adrDir) : [])
    .map((f) => f.match(/^(ADR-\d{3})/)?.[1])
    .filter(Boolean),
);

function scanAdrRefs(relPath, text) {
  for (const ref of new Set(text.match(/ADR-\d{3}/g) ?? [])) {
    if (!adrIds.has(ref)) {
      findings.push(`${relPath}: references ${ref} but no such file exists in adr/`);
    }
  }
}
for (const f of reqFiles) scanAdrRefs(`requirements/${f}`, read(join(reqDir, f)) ?? "");
for (const f of ["design.md", "execution-plan.md", "scope.md"]) {
  const t = read(join(dir, f));
  if (t) scanAdrRefs(f, t);
}
// ADRs may reference each other too
for (const f of existsSync(adrDir) ? readdirSync(adrDir).filter((x) => x.endsWith(".md")) : []) {
  scanAdrRefs(`adr/${f}`, read(join(adrDir, f)) ?? "");
}

// ---- 4: risks have mitigations ---------------------------------------------
const risks = read(join(dir, "risk-register.md"));
if (risks !== null) {
  for (const line of risks.split(/\r?\n/)) {
    const m = line.match(/^\|\s*(R-\d+)\s*\|/);
    if (!m) continue;
    const cells = line.split("|").map((c) => c.trim());
    // | ID | Category | Description | Likelihood | Impact | Mitigation | Status |
    const mitigation = cells[6] ?? "";
    if (!mitigation) {
      findings.push(`risk-register.md: ${m[1]} has no mitigation`);
    }
  }
}

// ---- 5: design declares scope / component paths -----------------------------
const design = read(join(dir, "design.md"));
if (design === null) {
  findings.push("design.md: missing — nothing declares component Scope/paths");
} else if (!/^##\s+(Scope|Component Paths)\s*$/im.test(design)) {
  findings.push("design.md: no '## Scope' or '## Component Paths' section — component paths undeclared");
}

// ---- report ------------------------------------------------------------------
if (findings.length === 0) {
  console.log("consistency-check: clean");
  process.exit(0);
}
console.log(`consistency-check: ${findings.length} finding(s)`);
for (const f of findings) console.log(`  ✖ ${f}`);
process.exit(1);
