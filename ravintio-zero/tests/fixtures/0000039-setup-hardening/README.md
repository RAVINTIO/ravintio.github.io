# Fixtures for 0000039-setup-hardening-release-sizing

The `setup.sh` and `setup.ps1` suites read the same files, so both scripts face the same input.

- `invalid-settings.json`: invalid JSON (a trailing comma). It holds the planted value `PLANTED-0000039-secret-value`, which must never appear in setup output (req-001).
- `single-object-hooks.json`: four hook entries whose `hooks` value is one object, not an array (req-002). Two run a RAVINTIO module and two run a user command.
- `deep-settings.json`: a `custom` value nested 15 levels deep, ending in `"leaf-0000039"` (req-003).
