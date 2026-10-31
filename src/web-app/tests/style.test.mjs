import { describe, test } from 'node:test';
import assert from 'node:assert/strict';
import { pageSlugs, readPage, stripCode } from './helpers.mjs';

// Words and marks the style guide bans in prose.
const BLOCKLIST = [
  /\bsimple\b/i, /\bsimply\b/i, /\beasy\b/i, /\bjust\b/i, /\bobviously\b/i,
  /\bhonest(ly)?\b/i, /\bfrankly\b/i, /\bcandidly\b/i, /\bto be fair\b/i,
  /\bload-bearing\b/i, /\bcrux\b/i, /\blinchpin\b/i,
  /\bwhitelist\b/i, /\bblacklist\b/i, /\bslave\b/i, /\bmaster\b/i,
  /\bsanity check\b/i, /\bcrazy\b/i, /\binsane\b/i, /\bdumb\b/i, /\blame\b/i, /\bblind to\b/i, /\bcripple/i,
  /\bkill(s|ed|ing)?\b/i, /\bhang(s|ing)?\b/i, /\bhit(s|ting)?\b/i,
  /\bliterally\b/i, /\butilis/i, /\bleverag/i, /\bfunctionality\b/i,
  /\bin order to\b/i, /\bprior to\b/i, /\badditionally\b/i, /\bwith regard to\b/i, /\bfacilitat/i,
  /\bplease note\b/i, /\bas you can see\b/i, /\bman-hours\b/i,
  /—/, /;/, /!/,
];

// Human-confirmed copy where the word names the design goal rather than judging a task (0000009 US-001).
const AGREED_PHRASES = [/as simple as the problem allows/gi];

const MAX_WORDS = 24;

// Prose lines only: drop code, tables, headings, HTML, and link targets.
function proseUnits(markdown) {
  return stripCode(markdown)
    .split('\n')
    .filter(line => !/^\s*(\||#|<|>\s*\[!)/.test(line))
    .map(line => line.replace(/^\s*([-*]|\d+\.)\s+/, '').replace(/\*\*|__|[*_]/g, ''))
    .join('\n')
    .split(/\n\s*\n|\n(?=\S)/)
    .flatMap(block => block.replace(/\s+/g, ' ').split(/(?<=[.?:])\s+/))
    .map(s => s.trim())
    .filter(Boolean);
}

describe('req-002-zero-adoption-guide: AC-3 prose meets the style rules', () => {
  test('no sentence on any page reaches 25 words', () => {
    const long = pageSlugs().flatMap(slug => proseUnits(readPage(slug))
      .filter(s => s.split(/\s+/).length > MAX_WORDS)
      .map(s => `${slug}: ${s}`));
    assert.deepEqual(long, []);
  });

  test('no page uses a blocklisted word or mark in prose', () => {
    const hits = [];
    for (const slug of pageSlugs()) {
      for (const unit of proseUnits(readPage(slug))) {
        const s = AGREED_PHRASES.reduce((acc, re) => acc.replace(re, ' '), unit);
        for (const re of BLOCKLIST) if (re.test(s)) hits.push(`${slug}: ${re} in "${s}"`);
      }
    }
    assert.deepEqual(hits, []);
  });
});
