---
title: "Orchestrator reference: Discovery coaching openers"
summary: "The Opening Briefing and the Decomposition sizing rules."
status: "active"
version: "1.0.0"
---
# Orchestrator reference: Discovery coaching openers

> Moved verbatim from `SKILL.md`. Read this file before you act on the topic. The Pack Index in `SKILL.md` lists the trigger.

### Opening Briefing

On a fresh start (no resume detected), open with:

```
P0 Discovery: Starting

Pipeline: P0 Discovery -> P1 Plan -> P2 Implement -> P3 Validate and Accept -> P4 Ship

Tool detected: {tool name or "unknown"}
Hooks status:
  - gate-write (PreToolUse): {registered / not registered / unknown}
  - check-design (UserPromptSubmit): {registered / not registered / unknown}

{If any hook is not registered:}
  Enforcement hooks not detected. Run: ./ravintio-zero/setup.sh {tool}
  Until hooks are registered, scope enforcement is instruction-based only.

Reading feature brief…
```

Detect the tool from `CLAUDE_CODE_*` env vars or a `.claude/` directory. Check hook registration by looking for `gate-write` in `.claude/settings.json`. Read `plan/current/feature-brief.md` before coaching begins.

### Decomposition

Size each release against a point budget. The budget comes from the optional `releaseSize` field in `product.yml`. If `releaseSize` is absent, use `medium`.

| `releaseSize` | Budget (points) |
|---------------|-----------------|
| `small` | 4 |
| `medium` (default) | 8 |
| `large` | 14 |

Estimate a size class for each candidate requirement from the files it is likely to touch.

| Class | Files touched | Points |
|-------|---------------|--------|
| S | 1 to 2 | 1 |
| M | 3 to 6 | 2 |
| L | 7 or more | 4 |

Recommend a fill from the backlog up to the budget. The human confirms the fill. If the candidates exceed the budget, recommend a split. If `releaseSize` holds an unknown value, note it in `discovery.md`, use the `medium` budget, and ask the human to fix the field.

With more than 5 or 6 features, group them into waves. Each wave is a separate pipeline run that reads the prior wave's manifests rather than its code. For multi-component work in one repository, follow `ravintio-zero/standards/monorepo-standards.md`. When two components need the same data, one owns it and the other consumes it through a defined interface. Shared writes are a Hard Limit violation: coach a redesign.

### Past retrospectives

When you write `discovery.md`, add the newest three records in `plan/retrospectives/`, with the open changes they filed. If the folder is empty, write "none". Coach the first question from what those records say to keep and to change.
