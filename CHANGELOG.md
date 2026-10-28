# Changelog

User-visible changes. For older details, see Git history.

## [Unreleased]

- Added the Snarfum Industries Alfred theme at
  `config/alfred/snarfum-industries.alfredappearance`. Open it to import; it is
  not linked by bootstrap.
- Use Debian's `fdfind` for fzf defaults and picker helpers when `fd` is absent.
- Restored Zsh completion ownership/permission audits on every startup and
  guarded fzf ZLE integration so captured interactive shells stay quiet.
- Pinned Zsh plugins to the installed baseline commits, with origin and clean
  worktree verification. Existing plugins advance only with `--upgrade-plugins`
  and only by fast-forward to manifest pins, not with `--upgrade-packages`.
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
- Saved the configurable Obsidian Search Alfred workflow under
  `config/alfred/workflows/obsidian-search/` for manual import; machine-specific
  vault settings remain outside the repo.
