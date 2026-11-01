import { test, expect, type Page } from '@playwright/test';

const paths = ['/', '/docs/pipeline.html'];
const DARK_BG = 'rgb(2, 6, 23)'; // --bg-color in [data-theme="dark"], src/style.css
const THEME_KEY = 'ravintio-theme';

// Blocks every external script request, so the module script (main.ts) never runs.
// What the page shows after load is then exactly what the inline script set, with no timing involved.
async function loadWithoutModule(page: Page, path: string) {
  await page.route('**/*', (route) =>
    route.request().resourceType() === 'script' ? route.abort() : route.continue(),
  );
  await page.goto(path, { waitUntil: 'load' });
  return page.evaluate(() => ({
    theme: document.documentElement.dataset.theme,
    htmlBg: getComputedStyle(document.documentElement).backgroundColor,
    bodyBg: getComputedStyle(document.body).backgroundColor,
  }));
}

for (const path of paths) {
  test(`req-006 AC-1: ${path} paints dark first when dark is saved`, async ({ page }) => {
    await page.addInitScript((key) => localStorage.setItem(key, 'dark'), THEME_KEY);
    const state = await loadWithoutModule(page, path);
    expect(state.theme).toBe('dark');
    expect([state.htmlBg, state.bodyBg]).toContain(DARK_BG);
  });

  test(`req-006 AC-2: ${path} paints light first when light is saved`, async ({ page }) => {
    await page.addInitScript((key) => localStorage.setItem(key, 'light'), THEME_KEY);
    const state = await loadWithoutModule(page, path);
    expect(state.theme).toBe('light');
  });

  test(`req-006 AC-3: ${path} follows a dark system preference when nothing is saved`, async ({ browser }) => {
    const context = await browser.newContext({ colorScheme: 'dark' });
    const page = await context.newPage();
    const state = await loadWithoutModule(page, path);
    await context.close();
    expect(state.theme).toBe('dark');
  });
}
