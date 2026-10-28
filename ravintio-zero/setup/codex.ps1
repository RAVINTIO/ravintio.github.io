# Codex - tool configuration
# https://developers.openai.com/codex
#
# Skills:    .agents/skills/{name}/SKILL.md      (scanned from the working directory up to the repo root)
# Workflows: none                                 (Codex has no slash-command folder that setup fills)
# Boot file: AGENTS.md                            (project root)
# Hooks:     .codex/hooks.json                    (merge-guard only, see Install-CodexHooks in setup.ps1)

@{
    SkillsDir      = '.agents\skills'
    WorkflowsDir   = ''
    BootFile       = 'AGENTS.md'
    BootTemplate   = "ravintio-zero/templates/codex-boot.md"
    SettingsFile   = ''
    # Codex has no settings.json that RAVINTIO writes. Hooks go to hooks.json.
    CodexHooksFile = '.codex/hooks.json'
    CodexHooksDir  = '.codex/hooks/enforcement'
}
