import { test, expect } from '@playwright/test';

// REQ-002 AC-2: GitHub Pages serves 404.html at any depth, so its assets must resolve from the root.
test('req-002 AC-2: the 404 page loads its assets at a nested missing path', async ({ page }) => {
  const missing = '/docs/missing/page.html';
  const errors: string[] = [];
  const assets: { url: string; status: number }[] = [];
  page.on('pageerror', (e) => errors.push(e.message));
  page.on('console', (m) => {
    // Chrome reports the 404 document itself as a console error, which is the expected status.
    if (m.type() === 'error' && !m.location().url.endsWith(missing)) errors.push(m.text());
  });
  page.on('response', (r) => {
    const type = r.request().resourceType();
    if (type === 'stylesheet' || type === 'script') assets.push({ url: r.url(), status: r.status() });
  });
  const response = await page.goto(missing, { waitUntil: 'load' });
  expect(response?.status()).toBe(404);
  await expect(page.locator('main h1')).toBeVisible();
  expect(assets.filter((a) => a.url.startsWith('http://localhost')).length).toBeGreaterThan(0);
  expect(assets.filter((a) => a.status !== 200)).toEqual([]);
  expect(errors).toEqual([]);
});
