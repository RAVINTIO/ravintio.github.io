# Migration 0005 - Initiative rename

**Target standard:** `plan/roadmap/{id}-{slug}/initiative.md`, `.github/workflows/ravintio.yml`, and `plan/.initiative-logs/`
**Scope:** consumer repo root
**Applies when:** a `plan/roadmap/*/roadmap.md` file exists, or `.github/workflows/ravintio.yml` holds a `roadmap/**` pattern. In any other repo, including the pack source, the migration stays pending and nothing runs.
**Safe to skip:** No. The pack reads `initiative.md` and the `initiative/**` branch pattern, so a draft or pattern left under the old name goes unseen. Re-running is safe.

---

## What this migration does

The pack renamed the charted unit of work from "roadmap" to "initiative". The `plan/roadmap/` folder keeps its name because it holds the long-term roadmap. A consumer repo holds three things that setup does not move:

- each draft at `plan/roadmap/{id}-{slug}/roadmap.md`
- the `roadmap/**` branch pattern in `.github/workflows/ravintio.yml`
- the log folder `plan/.roadmap-logs/`

The helper renames each draft to `initiative.md` in the same folder. It changes `roadmap/**` to `initiative/**` in the workflow. It renames `plan/.roadmap-logs/` to `plan/.initiative-logs/`. It uses `git mv` for tracked paths and deletes nothing.

The helper stops before any change in these cases:

- `plan/current-roadmap/` exists, so an initiative is active.
- A draft folder holds both `roadmap.md` and `initiative.md`.
- Both log folders exist.
- A path the helper moves or edits is a symlink.

---

## Migrator instructions

1. Check that `ravintio-zero/` exists in the project root. If it doesn't, ask the human to copy the new `ravintio-zero/` folder into the project, then continue. The project root can sit below the git top level.

2. If `plan/current-roadmap/` exists, tell the human to finish or park the active initiative first. Stop until they do.

3. Show: `Will run the helper from the project root. It renames each plan/roadmap/*/roadmap.md to initiative.md, changes roadmap/** to initiative/** in ravintio.yml, and renames plan/.roadmap-logs/ to plan/.initiative-logs/.`
   Ask: `Proceed? (y/n)`

4. If yes, run the helper that matches the shell:
   - Bash: `bash ravintio-zero/migrations/migrate-initiative-rename.sh`
   - PowerShell: `ravintio-zero/migrations/migrate-initiative-rename.ps1`

5. If the helper exits non-zero, show its output and stop. It changed nothing. Do not retry until the human fixes the cause:
   - `plan/current-roadmap/` exists. The human finishes or parks the initiative.
   - A draft folder holds both `roadmap.md` and `initiative.md`. The human keeps one file.
   - Both `plan/.roadmap-logs/` and `plan/.initiative-logs/` exist. The human merges or deletes one.
   - A moved path or the workflow file is a symlink, dangling or not. The human replaces the link with a real file or folder.

6. If the helper exits 0, ask the human to check `git status` for the renames. Ask: `Confirmed? (y/n)`

7. Tell the human to rename any exported `RAVINTIO_ROADMAP_MODEL` or `RAVINTIO_ROADMAP_MAX_TURNS` variable to `RAVINTIO_INITIATIVE_MODEL` or `RAVINTIO_INITIATIVE_MAX_TURNS`. The driver stops at start if it finds an old name.

The helper moves this file to `ravintio-zero/migrations/_done/` after a run that changes the repo. If you made the changes by hand, or the human explicitly skips the migration, move it yourself.
