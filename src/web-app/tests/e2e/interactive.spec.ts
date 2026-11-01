import { test, expect } from '@playwright/test';
import { pagePaths } from './pages';

const pages = pagePaths();
const THEME_KEY = 'ravintio-theme';

// A diagram page reloads on toggle, so the test waits on the attribute rather than a fixed delay.
for (const path of ['/', '/docs/pipeline.html']) {
  test(`req-002 AC-1: ${path} theme toggle switches and persists`, async ({ page }) => {
    await page.goto(path, { waitUntil: 'load' });
    const html = page.locator('html');
    const before = await html.getAttribute('data-theme');
    const expected = before === 'dark' ? 'light' : 'dark';

    await page.locator('#theme-toggle').click();
    await expect(html).toHaveAttribute('data-theme', expected);
    expect(await page.evaluate((k) => localStorage.getItem(k), THEME_KEY)).toBe(expected);

    await page.reload({ waitUntil: 'load' });
    await expect(html).toHaveAttribute('data-theme', expected);
  });
}

test('req-002 AC-2: page list is closed on a phone and opens on click', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto('/docs/pipeline.html', { waitUntil: 'load' });
  const list = page.locator('.doc-sections__disclosure');
  await expect(list).not.toHaveJSProperty('open', true);
  await list.locator('summary').click();
  await expect(list).toHaveJSProperty('open', true);
});

test('req-002 AC-2: page list is open at 1280 px', async ({ page }) => {
  await page.setViewportSize({ width: 1280, height: 800 });
  await page.goto('/docs/pipeline.html', { waitUntil: 'load' });
  await expect(page.locator('.doc-sections__disclosure')).toHaveJSProperty('open', true);
});

test('req-002 AC-3: every Mermaid diagram renders as an SVG', async ({ page }) => {
  const withDiagram: string[] = [];
  for (const path of pages) {
    await page.goto(path, { waitUntil: 'load' });
    if ((await page.locator('pre.mermaid').count()) > 0) withDiagram.push(path);
  }
  // The list reporter hides skip reasons, so print the reason as well.
  const reason = 'no page holds a Mermaid diagram';
  if (withDiagram.length === 0) console.log(`req-002 AC-3 skipped: ${reason}`);
  test.skip(withDiagram.length === 0, reason);

  for (const path of withDiagram) {
    await page.goto(path, { waitUntil: 'load' });
    const diagrams = page.locator('pre.mermaid');
    for (let i = 0; i < (await diagrams.count()); i++) {
      await expect(diagrams.nth(i).locator('svg')).toHaveCount(1, { timeout: 15_000 });
    }
  }
});
