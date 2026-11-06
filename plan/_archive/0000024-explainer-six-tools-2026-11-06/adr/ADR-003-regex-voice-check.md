---
title: "ADR 003: Check passive voice with a regex and an allowlist"
summary: "style.test.mjs flags be-verbs before a participle, with an allowlist for adjective uses."
status: "accepted"
version: "0.1.0"
---
# ADR-003 - Check passive voice with a regex and an allowlist

**Skill:** [plan](../skills/ravintio-plan/SKILL.md)
**Feature:** 0000024-explainer-six-tools
**Component:** web-app
**Date:** 2026-11-06

## Context

The style guide treats "is", "are", "was", or "were" before a past participle as passive voice. `style.test.mjs` checks length and a word blocklist, but not voice. Some matches are adjectives, such as "the PRs are merged" describing a state.

## Decision

Add a test that flags a be-verb, an optional adverb, and a participle. A participle is a word ending in "ed" or a word from a closed list of irregular forms. An allowlist of exact phrases, each with a comment, covers adjective uses. The test also runs on a sample passive sentence to prove it can fail.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| No automated check | No upkeep | Passive sentences return, as backlog 0000021 shows | The human chose the check |
| Part-of-speech tagger | Fewer false positives | New dependency | ADR-001 |

## Affected Components

| Component | Impact |
|-----------|--------|
| web-app | New test in `style.test.mjs` |
| site-content | Every page must pass it |

## Consequences

**Positive:**
- Passive sentences fail CI before review.

**Negative:**
- Authors must add genuine adjective uses to the allowlist.

**Risks:**
- R-001: the allowlist grows.

## Related ADRs

- ADR-001 - depends-on
