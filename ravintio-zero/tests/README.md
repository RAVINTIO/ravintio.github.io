# RAVINTIO Tests

This directory holds the pack's own test suite. Bash suites run on macOS,
Linux, and WSL. PowerShell suites run on Windows PowerShell 5.1 and
PowerShell 7. All suites cover the Claude Code target only.

## Layout

| Path | Contents |
|------|----------|
| `test-*.sh` | Per-feature Bash suites |
| `test-*.ps1` | Per-feature PowerShell suites, which run `setup.ps1` |
| `helpers/` | Shared assertions (`assert.sh`, `assert.ps1`) and the `setup.ps1` workspace helper |
| `regression/` | The long-term regression pack and its manifest |
| `run-tests.sh` | The runner for every suite |
| `run-tests.ps1` | The runner for the PowerShell suites only |

## Running the tests

```bash
bash ravintio-zero/tests/run-tests.sh
```

The runner discovers every `test-*.sh` and `test-*.ps1` in this directory by
glob. No suite is registered by hand. Add a conforming file and it runs on the
next invocation. After the per-feature suites, the runner executes every suite
under `regression/` and reports the two sets separately.

The runner runs PowerShell suites with `pwsh`. If `pwsh` isn't on the `PATH`,
it prints how many it skipped. Set `RAVINTIO_REQUIRE_PWSH=1` to make that skip
fail the run, or `RAVINTIO_PWSH` to point at another PowerShell 7 program.

Before any suite runs, the runner checks every file under this directory. A file
that is neither a suite nor on the runner's known list makes the run fail, and
the runner names it. If you add a helper or data file, add it to
`KNOWN_NON_SUITES` in `run-tests.sh`. To run only this check, set
`RAVINTIO_PREFLIGHT_ONLY=1`.

You can also run a single suite directly:

```bash
bash ravintio-zero/tests/test-commit-msg-hook.sh
```

To run only the PowerShell suites, under a host of your choice:

```powershell
powershell -NoProfile -File ravintio-zero/tests/run-tests.ps1
pwsh -NoProfile -File ravintio-zero/tests/run-tests.ps1
```

Suites create their own temporary workspaces where they need isolation and
clean up after themselves, so a run leaves your working tree unaffected.

## CI

The `windows-powershell` job in `.github/workflows/ravintio.yml` runs
`run-tests.ps1` on `windows-latest`, once under each host.

The `bash-suites` job runs `run-tests.sh` on `ubuntu-latest`. It sets
`RAVINTIO_REQUIRE_PWSH=1`, so the run fails if `pwsh` is missing. The job
also runs the `.ps1` suites under `pwsh` on Linux.

## The regression pack

`regression/` holds suites promoted from completed feature runs, so behaviour
proven in one feature stays covered in every later one.

`regression/regression-manifest.json` records each promoted test: its source
feature, promotion date, and promoter. `scripts/promote-to-regression.sh`
manages the manifest. Do not edit it by hand. `test-regression-pack.sh` fails
when a manifest entry has no file, or a suite has no entry.

## Adding a test

1. Name the file `test-{feature-id}-{description}.sh` or `.ps1`, and put it in
   this directory.
2. Source `helpers/assert.sh`, or dot-source `helpers/assert.ps1` and end with
   `Complete-Suite`.
3. Exit non-zero on failure. The runner counts a suite as failed on any
   non-zero exit.
4. Keep a `.ps1` suite ASCII. Windows PowerShell 5.1 reads a file with no BOM as
   ANSI, so build non-ASCII test text from `[char]` codes.

The runner picks the file up automatically. Nothing else needs registering.

### Helper guards

- `print_summary` fails a Bash suite that calls an undefined `assert_*` function. It scans the suite for lines that start with an `assert_*` word and prints `FAIL: undefined assert function: {name}` for each name that is not a function. A call after `&&` or inside `$(...)` is not scanned.
- `assert_not_contains needle haystack message` passes when the needle is absent.
- `stale_install_skip_reason root` returns 0 and prints a reason when an initiative is active and `.claude/skills/.ravintio-manifest` is older than the newest pack skill. A suite that compares installed copies prints `SKIP: {reason}` instead of comparing.

### Step activity

- `test-0000240-req-001-driver-stream-args.sh` checks the driver passes `--output-format stream-json --verbose`, keeps the log at mode 600, and prints no step content.
- `test-0000240-req-002-activity-lines.sh` checks that the watcher prints one `I-C Run: activity:` line per event, in order, at 200 characters or fewer, and that the skill and standards describe them. `--since-bytes {n}` treats the first n bytes of the step log as seen.
