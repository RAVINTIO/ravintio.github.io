import { defineConfig } from 'vite';
import { resolve } from 'path';
import { existsSync, readFileSync } from 'fs';
import type { Plugin } from 'vite';

// Build inputs come from the sectioned manifest (ADR-003), so new pages need no edit here.
const manifest = JSON.parse(readFileSync(resolve(__dirname, 'docs.manifest.json'), 'utf-8'));
const pageInputs: Record<string, string> = {};
for (const section of manifest.sections) {
  for (const page of section.pages) {
    pageInputs[page.file.replace(/\.html$/, '')] = resolve(__dirname, 'docs', page.file);
  }
}

// Vite preview has no 404.html support, so this serves dist/404.html with status 404
// for any missing path, as GitHub Pages does (REQ-002, ADR-003).
function githubPagesNotFound(): Plugin {
  return {
    name: 'github-pages-not-found',
    configurePreviewServer(server) {
      const dist = resolve(__dirname, 'dist');
      return () => {
        server.middlewares.use((req, res, next) => {
          const url = decodeURIComponent((req.url ?? '/').split('?')[0]);
          const target = resolve(dist, '.' + url);
          const found = url.endsWith('/') ? existsSync(resolve(target, 'index.html')) : existsSync(target);
          if (found || !target.startsWith(dist)) return next();
          res.statusCode = 404;
          res.setHeader('Content-Type', 'text/html; charset=utf-8');
          res.end(readFileSync(resolve(dist, '404.html')));
        });
      };
    },
  };
}

export default defineConfig({
  plugins: [githubPagesNotFound()],
  base: './', // For GitHub Pages standard relative layout
  // No SPA fallback, so the dev and preview servers return 404 for a missing page, as GitHub Pages does.
  appType: 'mpa',
  build: {
    rollupOptions: {
      input: {
        main: resolve(__dirname, 'index.html'),
        // GitHub Pages serves 404.html for any missing path (REQ-002).
        notFound: resolve(__dirname, '404.html'),
        ...pageInputs,
        sitemap: resolve(__dirname, 'docs/sitemap.html'),
      }
    }
  }
});
