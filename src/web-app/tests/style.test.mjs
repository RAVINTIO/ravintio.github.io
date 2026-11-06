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

// Passive phrases from the nine sentences that backlog 0000021 lists.
const LISTED_PASSIVES = {
  'six-tools': [/\bis designed to\b/i, /\bis meant to\b/i],
  'project-operations': [/commit messages are checked/i, /code is staged without documentation/i, /The pack is shared with the team/i],
  skills: [/after the design is confirmed/i],
};

// Irregular past participles. Regular ones end in "ed".
const IRREGULAR_PARTICIPLES = [
  'built', 'written', 'run', 'made', 'done', 'given', 'shown', 'taken', 'kept', 'set',
  'held', 'found', 'known', 'seen', 'sent', 'left', 'meant', 'put', 'read', 'bound',
  'chosen', 'drawn', 'driven', 'broken', 'spoken', 'hidden', 'begun', 'thrown', 'grown',
];

// A be-verb, an optional adverb, then a participle.
const PASSIVE = new RegExp(
  `\\b(is|are|was|were)\\s+(\\w+ly\\s+)?(\\w+ed|${IRREGULAR_PARTICIPLES.join('|')})\\b`, 'gi');

// Adjective uses that describe a state rather than an action done to the subject.
const ALLOWED_PHRASES = [
  /pull requests are merged/i, // first-run: asks about the state of earlier PRs
  /you are satisfied/i, // first-run: "satisfied" describes the reader's state
];

function passiveHits(sentence) {
  const s = ALLOWED_PHRASES.reduce((acc, re) => acc.replace(re, ' '), sentence);
  return [...s.matchAll(PASSIVE)].map(m => m[0]);
}

describe('req-003-active-voice: AC-1 listed sentences fixed', () => {
  for (const [slug, phrases] of Object.entries(LISTED_PASSIVES)) {
    test(`${slug} no longer holds the listed passive phrases`, () => {
      const page = readPage(slug);
      assert.deepEqual(phrases.filter(re => re.test(page)).map(String), []);
    });
  }
});

describe('req-003-active-voice: AC-2 voice check on every page', () => {
  test('the check flags a sample passive sentence', () => {
    assert.deepEqual(passiveHits('The file is checked by the hook.'), ['is checked']);
    assert.deepEqual(passiveHits('The site was quickly built.'), ['was quickly built']);
  });

  test('no page uses passive voice in prose outside the allowlist', () => {
    const hits = pageSlugs().flatMap(slug => proseUnits(readPage(slug))
      .flatMap(s => passiveHits(s).map(p => `${slug}: "${p}" in "${s}"`)));
    assert.deepEqual(hits, []);
  });
});
