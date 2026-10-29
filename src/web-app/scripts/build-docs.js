import fs from 'fs';
import path from 'path';
import { marked } from 'marked';

import { fileURLToPath } from 'url';
const __dirname = path.dirname(fileURLToPath(import.meta.url));

// site-content owns the pages. This script only reads them (ADR-002).
const PAGES_DIR = path.resolve(__dirname, '../../site-content/pages');
const OUT_DIR = path.resolve(__dirname, '../docs');
const MANIFEST_FILE = path.resolve(__dirname, '../docs.manifest.json');
const SITEMAP_DATA_FILE = path.resolve(__dirname, '../public/sitemap-data.json');
const REPO_URL = 'https://github.com/RAVINTIO/ravintio-zero';

const fail = message => {
  console.error(`ERROR: ${message}`);
  process.exit(1);
};

// --- Sectioned page manifest (ADR-003) ---
if (!fs.existsSync(MANIFEST_FILE)) fail(`docs.manifest.json not found at ${MANIFEST_FILE}`);
let manifest;
try {
  manifest = JSON.parse(fs.readFileSync(MANIFEST_FILE, 'utf-8'));
} catch (e) {
  fail(`docs.manifest.json is not valid JSON: ${e.message}`);
}
if (!Array.isArray(manifest.sections) || manifest.sections.length === 0) {
  fail('docs.manifest.json must have a non-empty "sections" array');
}
for (const section of manifest.sections) {
  if (!section.title || !Array.isArray(section.pages) || section.pages.length === 0) {
    fail('every manifest section needs a "title" and a non-empty "pages" array');
  }
}

// Flattened in section order for prev and next links.
const pages = manifest.sections.flatMap(section =>
  section.pages.map(page => ({ ...page, section: section.title })));

if (!fs.existsSync(PAGES_DIR)) fail(`pages folder not found at ${PAGES_DIR}`);
fs.rmSync(OUT_DIR, { recursive: true, force: true });
fs.mkdirSync(OUT_DIR, { recursive: true });

const escapeHtml = s => s
  .replace(/&/g, '&amp;')
  .replace(/</g, '&lt;')
  .replace(/>/g, '&gt;')
  .replace(/"/g, '&quot;');

// --- Shared page chrome ---
const ICON_SUN = '<svg class="sun-icon" xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="5"></circle><line x1="12" y1="1" x2="12" y2="3"></line><line x1="12" y1="21" x2="12" y2="23"></line><line x1="4.22" y1="4.22" x2="5.64" y2="5.64"></line><line x1="18.36" y1="18.36" x2="19.78" y2="19.78"></line><line x1="1" y1="12" x2="3" y2="12"></line><line x1="21" y1="12" x2="23" y2="12"></line><line x1="4.22" y1="19.78" x2="5.64" y2="18.36"></line><line x1="18.36" y1="5.64" x2="19.78" y2="4.22"></line></svg>';
const ICON_MOON = '<svg class="moon-icon" xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"></path></svg>';
const ICON_CODE = '<svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="code-icon" aria-hidden="true"><polyline points="20 18 24 12 20 6"></polyline><polyline points="4 6 0 12 4 18"></polyline><line x1="14" y1="2" x2="10" y2="22"></line></svg>';
const ICON_MENU = '<svg width="24" height="24" xmlns="http://www.w3.org/2000/svg" fill="none" class="menu-icon" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><line x1="3" y1="12" x2="21" y2="12"></line><line x1="3" y1="6" x2="21" y2="6"></line><line x1="3" y1="18" x2="21" y2="18"></line></svg>';

// Top nav links go to the first page of each section.
const topNavLinks = manifest.sections
  .map(s => `<a href="${s.pages[0].file}" class="nav-link">${escapeHtml(s.title)}</a>`)
  .join('\n            ');

function sectionNav(currentFile) {
  const groups = manifest.sections.map(section => {
    const links = section.pages.map(page => {
      const current = page.file === currentFile ? ' aria-current="page"' : '';
      return `<li><a href="${page.file}"${current}>${escapeHtml(page.title)}</a></li>`;
    }).join('');
    return `<div class="doc-sections__group"><p class="doc-sections__title">${escapeHtml(section.title)}</p><ul>${links}</ul></div>`;
  }).join('');
  return `<nav class="doc-sections" aria-label="Documentation">${groups}</nav>`;
}

function pageHtml({ title, content, currentFile, pagination }) {
  return `<!DOCTYPE html>
<html lang="en-GB">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>${escapeHtml(title)} - RAVINTIO Docs</title>
    <link rel="icon" type="image/png" sizes="32x32" href="../favicon-32x32.png">
    <link rel="icon" type="image/png" sizes="16x16" href="../favicon-16x16.png">
    <link rel="apple-touch-icon" sizes="180x180" href="../apple-touch-icon.png">
    <link rel="manifest" href="../site.webmanifest">
    <link rel="stylesheet" href="../src/style.css">
    <script type="module" src="../src/main.ts"></script>
  </head>
  <body>
    <div id="app">
      <a class="skip-link" href="#content">Skip to content</a>
      <nav class="glass-nav" aria-label="Site">
        <div class="nav-content">
          <a href="../index.html" class="logo"><img src="../img/ravintio-logo.png" alt="" width="32" height="32"><span class="wordmark">RAVINTIO</span></a>
          <div class="nav-links">
            ${topNavLinks}
          </div>
          <div class="nav-actions">
            <button id="theme-toggle" class="theme-toggle" aria-label="Toggle theme">${ICON_SUN}${ICON_MOON}</button>
            <a href="${REPO_URL}" class="code-icon-link" aria-label="RAVINTIO Zero on GitHub" title="RAVINTIO Zero on GitHub" target="_blank" rel="noopener noreferrer">${ICON_CODE}</a>
            <button class="hamburger-btn" aria-label="Toggle menu" title="Menu" aria-expanded="false">${ICON_MENU}</button>
          </div>
        </div>
      </nav>
      <div class="doc-layout">
        ${sectionNav(currentFile)}
        <main id="content" class="doc-container glass-panel">
          ${content}
          ${pagination}
        </main>
      </div>
      <footer class="footer">
        <div class="container">
          <div class="footer-content">
            <div class="brand"><img src="../img/ravintio-logo.png" alt="" width="28" height="28"><span class="wordmark">RAVINTIO</span></div>
            <div class="footer-links">
              <a href="sitemap.html">Sitemap</a>
              <a href="${REPO_URL}" target="_blank" rel="noopener noreferrer">GitHub</a>
            </div>
          </div>
        </div>
      </footer>
    </div>
  </body>
</html>
`;
}

// --- Markdown rendering ---
const slugify = text => text.toLowerCase()
  .replace(/<[^>]+>/g, '')
  .replace(/[^\w\s-]/g, '')
  .trim()
  .replace(/\s+/g, '-')
  .replace(/-+/g, '-');

marked.use({
  renderer: {
    heading({ tokens, depth, text }) {
      const html = this.parser.parseInline(tokens);
      return `<h${depth} id="${slugify(text)}">${html}</h${depth}>\n`;
    },
    code({ text, lang }) {
      if (lang === 'mermaid') return `<pre class="mermaid">${escapeHtml(text)}</pre>\n`;
      const cls = lang ? ` class="language-${escapeHtml(lang)}"` : '';
      return `<pre><code${cls}>${escapeHtml(text)}</code></pre>\n`;
    },
  },
});

// Page links are written as {slug}.md in the source.
const rewriteLinks = markdown => markdown.replace(/\]\(([a-z0-9-]+)\.md(#[^)]*)?\)/g, ']($1.html$2)');

function pagination(index) {
  const prev = pages[index - 1];
  const next = pages[index + 1];
  const link = (page, cls, label) => page
    ? `<a href="${page.file}" class="doc-pagination__${cls}">${label}<span class="doc-pagination__title">${escapeHtml(page.title)}</span></a>`
    : '<span class="doc-pagination__spacer"></span>';
  return `<nav class="doc-pagination" aria-label="Previous and next">
  ${link(prev, 'prev', '← Previous')}
  ${link(next, 'next', 'Next →')}
</nav>`;
}

// --- Undeclared and missing pages ---
const declared = new Set(pages.map(p => p.file.replace(/\.html$/, '.md')));
for (const f of fs.readdirSync(PAGES_DIR).filter(f => f.endsWith('.md'))) {
  if (!declared.has(f)) console.warn(`WARN: ${f} is not listed in docs.manifest.json and will not be built`);
}
for (const f of declared) {
  if (!fs.existsSync(path.join(PAGES_DIR, f))) fail(`docs.manifest.json lists ${f}, but it is missing from ${PAGES_DIR}`);
}

// --- Build pages ---
pages.forEach((page, index) => {
  const markdown = fs.readFileSync(path.join(PAGES_DIR, page.file.replace(/\.html$/, '.md')), 'utf-8');
  const html = pageHtml({
    title: page.title,
    content: marked.parse(rewriteLinks(markdown)),
    currentFile: page.file,
    pagination: pagination(index),
  });
  fs.writeFileSync(path.join(OUT_DIR, page.file), html, 'utf-8');
  console.log(`Generated: docs/${page.file}`);
});

// --- Sitemap ---
const sitemapData = pages.map(({ file, title, section }) => ({ file, title, section }));
fs.writeFileSync(SITEMAP_DATA_FILE, JSON.stringify(sitemapData, null, 2), 'utf-8');

const sitemapContent = '<h1>Sitemap</h1>\n' + manifest.sections.map(section =>
  `<h2>${escapeHtml(section.title)}</h2>\n<ul>\n` +
  section.pages.map(p => `<li><a href="${p.file}">${escapeHtml(p.title)}</a></li>`).join('\n') +
  '\n</ul>').join('\n');
fs.writeFileSync(path.join(OUT_DIR, 'sitemap.html'),
  pageHtml({ title: 'Sitemap', content: sitemapContent, currentFile: '', pagination: '' }), 'utf-8');
console.log('Generated: docs/sitemap.html');
