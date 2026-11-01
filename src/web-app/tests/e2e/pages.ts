import { readFileSync } from 'node:fs';

interface ManifestPage { file: string }
interface Manifest { sections: { pages: ManifestPage[] }[] }

// The homepage plus every manifest page, so a new page joins with no edit here.
export function pagePaths(): string[] {
  const manifest: Manifest = JSON.parse(
    readFileSync('docs.manifest.json', 'utf-8'), // Playwright runs from the config directory.
  );
  const docs = manifest.sections.flatMap((s) => s.pages.map((p) => `/docs/${p.file}`));
  return ['/', ...docs];
}
