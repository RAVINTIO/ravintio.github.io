import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';
import { mkdirSync, writeFileSync } from 'node:fs';
import { pagePaths } from './pages';
import { AXE_DIR } from './axe-report';

// REQ-001: scan every page in both themes against WCAG 2.2 AA (ADR-001, ADR-002).
const TAGS = ['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa', 'wcag22aa'];
const FAILING = new Set(['serious', 'critical']);

for (const path of pagePaths()) {
  for (const theme of ['light', 'dark'] as const) {
    test(`req-001 AC-1 to AC-3: ${path} has no serious or critical axe violations in ${theme}`, async ({ page }) => {
      await page.emulateMedia({ reducedMotion: 'reduce' });
      await page.addInitScript((t) => localStorage.setItem('ravintio-theme', t), theme);
      await page.goto(path, { waitUntil: 'load' });
      // Without this check, a rename of the storage key would scan the light theme twice and still pass.
      await expect(page.locator('html')).toHaveAttribute('data-theme', theme);
      // Mermaid marks each diagram once it renders, so the scan sees the final SVG.
      await page.waitForFunction(() => !document.querySelector('pre.mermaid:not([data-processed])'));
      const { violations } = await new AxeBuilder({ page }).withTags(TAGS).analyze();

      // REQ-001 AC-3: moderate and minor violations go to the report for the P3 review.
      const triage = violations
        .filter((v) => !FAILING.has(v.impact ?? ''))
        .map((v) => ({ page: path, theme, rule: v.id, impact: v.impact, nodes: v.nodes.map((n) => n.target.join(' ')) }));
      mkdirSync(AXE_DIR, { recursive: true });
      writeFileSync(`${AXE_DIR}/${path.replace(/\W+/g, '_')}-${theme}.json`, JSON.stringify(triage));

      // REQ-001 AC-2: a serious or critical violation fails and names its rule.
      const severe = violations
        .filter((v) => FAILING.has(v.impact ?? ''))
        .map((v) => `${v.id} (${v.impact}): ${v.nodes.map((n) => n.target.join(' ')).join(', ')}`);
      expect(severe, `${path} in ${theme}`).toEqual([]);
    });
  }
}
