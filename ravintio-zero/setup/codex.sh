# Codex - tool configuration
# https://developers.openai.com/codex
#
# Skills:    .agents/skills/{name}/SKILL.md      (scanned from the working directory up to the repo root)
# Workflows: none                                 (Codex has no slash-command folder that setup fills)
# Boot file: AGENTS.md                            (project root)
# Hooks:     .codex/hooks.json                    (merge-guard only, see install_codex_hooks in setup.sh)

TOOL_SKILLS_DIR=".agents/skills"
TOOL_WORKFLOWS_DIR=""

TOOL_BOOT_FILE="AGENTS.md"

TOOL_BOOT_TEMPLATE="ravintio-zero/templates/codex-boot.md"

# Codex has no settings.json that RAVINTIO writes. Hooks go to hooks.json.
TOOL_SETTINGS_FILE=""

TOOL_CODEX_HOOKS_FILE=".codex/hooks.json"
TOOL_CODEX_HOOKS_DIR=".codex/hooks/enforcement"
