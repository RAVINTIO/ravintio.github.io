// REQ-002: the build writes a 404 page with the site header and links back to the docs.
import { describe, test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { DIST } from './helpers.mjs';

const PAGE = path.join(DIST, '404.html');

describe('req-002-custom-404-page', () => {
  test('req-002 AC-1: the build writes 404.html with the header and links home', () => {
    assert.ok(fs.existsSync(PAGE), 'dist/404.html is missing');
    const html = fs.readFileSync(PAGE, 'utf-8');
    assert.match(html, /<base href="\/">/, 'the page resolves paths from the domain root (ADR-003)');
    assert.match(html, /<nav class="glass-nav[^"]*" aria-label="Site">/, 'the page has the site header');
    assert.equal(html.match(/<h1[\s>]/g)?.length, 1, 'the page has one h1');
    assert.match(html, /<main[^>]*>[\s\S]*href="\.\/index\.html"[\s\S]*<\/main>/, 'main links to the homepage');
    assert.match(html, /<main[^>]*>[\s\S]*href="\.\/docs\/sitemap\.html"[\s\S]*<\/main>/, 'main links to the sitemap');
    assert.match(html, /<meta name="description" content="[^"]{50,160}"/, 'the page has a description');
  });
});
