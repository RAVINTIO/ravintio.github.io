import { existsSync, readdirSync, readFileSync, writeFileSync } from 'node:fs';

// Each axe test writes its own file, so parallel workers never share one.
export const AXE_DIR = 'test-results/axe';
export const AXE_REPORT = 'test-results/axe-report.json';

// Global teardown: merge the per-test files into one report for the P3 review (REQ-001 AC-3).
export default function mergeAxeReport() {
  if (!existsSync(AXE_DIR)) return;
  const findings = readdirSync(AXE_DIR)
    .filter((f) => f.endsWith('.json'))
    .sort()
    .flatMap((f) => JSON.parse(readFileSync(`${AXE_DIR}/${f}`, 'utf-8')));
  writeFileSync(AXE_REPORT, JSON.stringify(findings, null, 2) + '\n');
}
