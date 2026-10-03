# Changelog

All notable user-visible changes are summarized here. Older implementation details and historical package churn are available in Git history.

## [Unreleased]

- Added `--creative` to macOS bootstrap to opt into the optional specialist
  creative/audio `Brewfile.creative`; the core `Brewfile` remains the default.
- Moved Go to mise alongside Node.js, Pi, and pnpm. The mise config is linked at
  its standard XDG path; project-local declarations can select project versions.
- Windows bootstrap now manages Windows host applications through winget and
  directs shell setup to Debian/Ubuntu in WSL. Native Windows Zsh links are not
  managed.
- Streamlined shared Zsh aliases by removing destructive, unsupported, and
  stale shortcuts; project-specific Collidascope commands moved to an ignored
  local-only module on the existing machine.
- Clarified safe rollback, package ownership, local-only shell modules, and
  platform support across project documentation.
- Pinned CI's Zsh-aware formatter and checksum verification so shell checks use
  the same formatting rules locally and on Ubuntu.
