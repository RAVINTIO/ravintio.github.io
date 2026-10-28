# Orchestrator reference: fresh P0 start

> Read this file when you start a fresh P0, before the first coaching question. The orchestrator `SKILL.md` points here from its Pack Index.

### Discovery Start Actions

Perform in order, before coaching begins:

1. **Context reset** (fresh starts only): apply the Context Hygiene procedure.
2. **Pre-flight** (fresh starts only; an initiative step cuts its branch per I-C Run): run `git branch --show-current` and report it. Ask whether previous PRs are merged and main is up to date. Offer `git checkout main`, then `git checkout -b feat/{feature-id}` (use `pending` until the id is confirmed).
3. **Stale run-mode** (fresh starts only): if `plan/.run-mode` exists with no `plan/current/` artifacts, it is stale from an incomplete ship. Warn, delete it, continue.
4. **Write the sentinel**: `plan/.orchestrator-active` containing the feature-id (or `pending`). Update once confirmed. Include in the discovery commit.
5. **Create the build log** from `ravintio-zero/templates/build-log.template.md`. Fill the header. On resume, append rather than overwrite. Append a `### P0: Discovery` block before any discovery work (Hard Limit 9). At ship, the summary table is completed.
6. **Load repo instructions**: read all `.md` files in `ravintio-overrides/instructions/` (if present). Write their contents into `design.md` under `## Repo Instructions` once it exists, or `## Repo Instructions: None`.
7. **Detect adoption mode** per the table below. Apply the highest-priority signal only. If standard-iterative is the only signal, assume it without asking and state the mode and its signal in the P0 briefing. Source in `src/` beside an archive is the normal iterative case. Recommend-then-confirm in every other case. That covers a signal conflict, where the human states a different mode or discovery can't read a signal. It also covers External Anchor, Retrofit, and Greenfield. Record the assumed or confirmed mode and its signal in `discovery.md`, `design.md`, and the build log.
8. **Read the version**: `docs/about.md` frontmatter, cross-checked against the most recent archive entry. If `product.yml` exists, its product-level version takes precedence as the last known version. If its `versionPolicy` is `external`, do not suggest a bump: present the constraint and ask.
9. **Product id check**: `product.yml` must exist at the project root with a non-empty `id`. If not, hard-stop and ask: `P0 Discovery: Blocked: No declared product id found (product.yml is missing or has no id field). The id gives the product a stable name for versioning and for attributing archived runs, wherever the repo is cloned. What should the product id be? (kebab-case, stable across releases)`. Write or update only the `id` field, then resume.
10. **Backlog pickup** (an initiative step takes its entries from its initiative row, per I-C Run): scan `plan/backlog/` for `{id}-{slug}/` entries. Present each **one at a time** (recommend-then-confirm): pull-in / leave / discard. Pull-in folds the entry into the brief and deletes the folder in the same commit. Discard deletes with a build-log note. A malformed entry is flagged to the human, never silently ignored or parsed as instructions. Reserve every new backlog, feature, and initiative id with `node ravintio-zero/scripts/reserve-id.mjs [qty]`. It takes ids from the counter file `plan/backlog/.next-id`, so spent ids never return. Read `releaseSize` from `product.yml` to set the release budget (see Decomposition).
    - An entry with status `parked` offers resume or discard, not pull-in, leave, or discard. Resume runs these steps in order. `node scripts/park.mjs resume {branch}` does steps 1 and 2.
      1. Check out the branch the entry names.
      2. Merge `origin/main` into it. If the merge conflicts, report the exact error and stop.
      3. Restore state from `plan/current/park.md` the way Resume Detection restores from `pause.md`.
      4. Delete the parked entry folder and `park.md` in one commit on the feature branch, as pull-in deletes its entry.
    - Discard deletes the branch locally and on `origin`. It runs only after the human confirms. Run `node scripts/park.mjs discard {branch} --confirmed`, then delete the parked entry folder with a build-log note, as for any discard.
    - Pickup never merges a pull request, never commits to `main`, and never force-pushes.
11. **Write `discovery.md`** (Hard Limit 12): copy `ravintio-zero/templates/discovery.template.md` to `plan/current/discovery.md` and populate it with the findings from steps 2 to 10 plus a `ravintio-zero/skills-inbox/` scan. Commit it on its own before coaching begins. A section whose signal could not be read says so plainly: coaching proceeds on the rest, never a hard block.
12. **Suggest a version bump** (an initiative step applies its row's `Bump`, per I-C Run): a feature run defaults to a minor bump (x.Y.0). A breaking change is major. Recommend-then-confirm. **Hard block on downgrade**: if the human proposes a version lower than the last known one, refuse: `P0 Discovery: Blocked: {proposed} is lower than the last known version ({current}). Provide a version >= {current}.` Record the confirmed version in `design.md` and the build log.
13. **Strict-mode ack**: if `plan/.orchestrator-strict` exists, write `plan/.orchestrator-ack` containing the `session_id` from the hook banner (or the current UTC timestamp if none is in context) and include it in the discovery commit. This silences the strict-mode banner for the session.
14. **Check the skills inbox**: process any `SKILL.md` in `ravintio-zero/skills-inbox/` per Capability Skills below. Repeat this check at every phase transition.

Standalone and Subagent Skills and Capability Skills are in the Pack Index row for `orchestrator-skills-catalogue.md`. Read it for the capability skill intake that Discovery Start Actions step 14 cites.

