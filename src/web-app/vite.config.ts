import { defineConfig } from 'vite';
import { resolve } from 'path';
import { readFileSync } from 'fs';

// Build inputs come from the sectioned manifest (ADR-003), so new pages need no edit here.
const manifest = JSON.parse(readFileSync(resolve(__dirname, 'docs.manifest.json'), 'utf-8'));
const pageInputs: Record<string, string> = {};
for (const section of manifest.sections) {
  for (const page of section.pages) {
    pageInputs[page.file.replace(/\.html$/, '')] = resolve(__dirname, 'docs', page.file);
  }
}

export default defineConfig({
  base: './', // For GitHub Pages standard relative layout
  build: {
    rollupOptions: {
      input: {
        main: resolve(__dirname, 'index.html'),
        ...pageInputs,
        sitemap: resolve(__dirname, 'docs/sitemap.html'),
      }
    }
  }
});
