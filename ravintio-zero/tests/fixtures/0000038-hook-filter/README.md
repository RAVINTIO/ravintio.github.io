# Hook filter fixtures (0000038)

The `.sh` and `.ps1` suites for 0000038 read these files, so both setup scripts face the same input.

- `settings-before.json` is the planted `settings.json`. It mixes RAVINTIO commands and user commands in shared entries.
- `expected-after.txt` lists every hook command after one setup run, one per line, as `event|matcher|command`.

An entry with no commands appears as one line with an empty command. Events appear in the order `PreToolUse`, `UserPromptSubmit`, then any others. Within an event, lines keep their file order.
