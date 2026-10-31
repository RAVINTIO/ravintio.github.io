// Shared paths and readers for the site tests. Node built-ins only (ADR-001).
import fs from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));

export const WEB_APP = path.resolve(here, '..');
export const REPO = path.resolve(WEB_APP, '../..');
export const PAGES_DIR = path.join(REPO, 'src/site-content/pages');
export const DIST = path.join(WEB_APP, 'dist');
export const DIST_DOCS = path.join(DIST, 'docs');
export const PACK = path.join(REPO, 'ravintio-zero');

// The confirmed page structure from design.md.
export const EXPECTED_SECTIONS = [
  { title: 'RAVINTIO', pages: [
    ['what-is-ravintio', 'What is RAVINTIO?'],
    ['six-tools', 'The six tools'],
  ] },
  { title: 'Zero', pages: [
    ['zero-overview', 'Zero overview'],
    ['install-zero', 'Install Zero'],
    ['first-run', 'Your first run'],
    ['pipeline', 'The pipeline'],
    ['project-operations', 'Project operations'],
  ] },
  { title: 'Reference', pages: [
    ['skills', 'Skills'],
    ['standards', 'Standards'],
    ['templates', 'Templates'],
  ] },
];

export function readManifest() {
  return JSON.parse(fs.readFileSync(path.join(WEB_APP, 'docs.manifest.json'), 'utf-8'));
}

export function readPage(slug) {
  return fs.readFileSync(path.join(PAGES_DIR, `${slug}.md`), 'utf-8');
}

export function pageSlugs() {
  return fs.readdirSync(PAGES_DIR).filter(f => f.endsWith('.md')).map(f => f.slice(0, -3));
}

export function readBuilt(slug) {
  return fs.readFileSync(path.join(DIST_DOCS, `${slug}.html`), 'utf-8');
}

export function trackedFiles() {
  return execFileSync('git', ['ls-files', '-z'], { cwd: REPO, encoding: 'utf-8' })
    .split('\0').filter(Boolean);
}

export function walk(dir) {
  if (!fs.existsSync(dir)) return [];
  return fs.readdirSync(dir, { withFileTypes: true }).flatMap(e => {
    const p = path.join(dir, e.name);
    return e.isDirectory() ? walk(p) : [p];
  });
}

// Removes fenced code, inline code, and URLs so prose checks see prose only.
export function stripCode(markdown) {
  return markdown
    .replace(/```[\s\S]*?```/g, ' ')
    .replace(/`[^`\n]*`/g, ' ')
    .replace(/\]\([^)]*\)/g, ']')
    .replace(/https?:\/\/\S+/g, ' ');
}

// Splits a built page into its H2 sections: [{ title, html }].
export function builtSections(slug) {
  const parts = readBuilt(slug).split(/<h2 id="[^"]*">/).slice(1);
  return parts.map(p => {
    const end = p.indexOf('</h2>');
    return { title: p.slice(0, end), html: p.slice(end + 5) };
  });
}

// Returns the bold lead text of each list item in a block of built HTML.
export function boldLeads(html) {
  return [...html.matchAll(/<li><strong>([^<]*)<\/strong>/g)].map(m => m[1]);
}
