import { test, expect, type Page } from '@playwright/test';
import { pagePaths } from './pages';

const pages = pagePaths();

// Opens a page and returns its response status plus every console error and page error.
async function load(page: Page, path: string) {
  const errors: string[] = [];
  page.on('console', (m) => {
    if (m.type() === 'error') errors.push(`console: ${m.text()}`);
  });
  page.on('pageerror', (e) => errors.push(`pageerror: ${e.message}`));
  const response = await page.goto(path, { waitUntil: 'load' });
  return { status: response?.status(), errors };
}

for (const path of pages) {
  test(`req-001 AC-1: ${path} loads with status 200 and no errors`, async ({ page }) => {
    const { status, errors } = await load(page, path);
    expect(status).toBe(200);
    expect(errors).toEqual([]);
  });

  test(`req-001 AC-3: ${path} has no sideways scroll at 390 px`, async ({ page }) => {
    await page.setViewportSize({ width: 390, height: 844 });
    await page.goto(path, { waitUntil: 'load' });
    const { scrollWidth, innerWidth } = await page.evaluate(() => ({
      scrollWidth: document.documentElement.scrollWidth,
      innerWidth: window.innerWidth,
    }));
    expect(scrollWidth).toBeLessThanOrEqual(innerWidth);
  });
}

test('req-001 AC-2: internal links and anchors resolve', async ({ page, request, baseURL }) => {
  const origin = new URL(baseURL!).origin;
  const failures: string[] = [];
  // Each link is { source page, raw href, resolved URL }, deduplicated by source and href.
  const links: { source: string; href: string; url: URL }[] = [];

  for (const path of pages) {
    await page.goto(path, { waitUntil: 'load' });
    const hrefs = await page.$$eval('a[href]', (as) => as.map((a) => a.getAttribute('href') ?? ''));
    for (const href of new Set(hrefs)) {
      if (/^(mailto:|tel:|javascript:)/i.test(href)) continue;
      const url = new URL(href, page.url());
      if (url.origin !== origin) continue;
      links.push({ source: path, href, url });
    }
  }

  // Check each target URL once, keeping its HTML for fragment lookups.
  const targets = new Map<string, { status: number; ids: Set<string> }>();
  for (const { url } of links) {
    const key = url.origin + url.pathname + url.search;
    if (targets.has(key)) continue;
    const res = await request.get(key);
    const ids = new Set<string>();
    if (res.status() === 200 && (res.headers()['content-type'] ?? '').includes('text/html')) {
      const html = await res.text();
      for (const m of html.matchAll(/\s(?:id|name)\s*=\s*["']([^"']+)["']/g)) ids.add(m[1]);
    }
    targets.set(key, { status: res.status(), ids });
  }

  for (const { source, href, url } of links) {
    const target = targets.get(url.origin + url.pathname + url.search)!;
    if (target.status !== 200) {
      failures.push(`${source} -> ${href}: status ${target.status}`);
    } else if (url.hash.length > 1 && !target.ids.has(decodeURIComponent(url.hash.slice(1)))) {
      failures.push(`${source} -> ${href}: no element with id or name "${url.hash.slice(1)}"`);
    }
  }

  expect(failures, failures.join('\n')).toEqual([]);
});

test('req-003 AC-1: the homepage has one main#content that the skip link targets', async ({ page }) => {
  await page.goto('/', { waitUntil: 'load' });
  await expect(page.locator('main#content')).toHaveCount(1);
  const skipLink = page.locator('a[href="#content"]');
  await expect(skipLink).toHaveCount(1);
  await expect(page.locator('#content')).toHaveCount(1);
  expect(await page.locator('#content').evaluate((el) => el.tagName)).toBe('MAIN');
});

for (const path of pages) {
  test(`req-003 AC-2: ${path} has exactly one main`, async ({ page }) => {
    await page.goto(path, { waitUntil: 'load' });
    await expect(page.locator('main')).toHaveCount(1);
  });
}
