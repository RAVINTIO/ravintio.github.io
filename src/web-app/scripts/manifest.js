// Pure helpers for build-docs.js, kept apart so tests can import them without a build.

export const escapeHtml = s => s
  .replace(/&/g, '&amp;')
  .replace(/</g, '&lt;')
  .replace(/>/g, '&gt;')
  .replace(/"/g, '&quot;');

// Every page needs a meta description (0000024 ADR-002).
export function checkDescriptions(manifest) {
  for (const page of manifest.sections.flatMap(s => s.pages)) {
    if (typeof page.description !== 'string' || page.description.trim() === '') {
      throw new Error(`docs.manifest.json page ${page.file} has no "description"`);
    }
  }
}
