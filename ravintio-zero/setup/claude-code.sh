# Claude Code - tool configuration
# https://docs.anthropic.com/en/docs/claude-code
#
# Skills:    .claude/skills/{name}/SKILL.md      (auto-discovered)
# Workflows: .claude/commands/{name}.md           (becomes /name slash command)
# Boot file: CLAUDE.md                            (project root)

TOOL_SKILLS_DIR=".claude/skills"
TOOL_WORKFLOWS_DIR=".claude/commands"

TOOL_BOOT_FILE="CLAUDE.md"

TOOL_BOOT_TEMPLATE="ravintio-zero/templates/standard-boot.md"

TOOL_SETTINGS_FILE=".claude/settings.json"
