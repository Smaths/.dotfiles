# Security Policy

## Secrets

Do not commit secrets to this repository.

Forbidden in git history:

- API tokens
- SSH private keys
- cloud credentials
- session cookies/passwords

Use system secret stores instead:

- macOS Keychain
- 1Password / 1Password CLI

## Handling Sensitive Config

- Keep machine-local secret config out of tracked files.
- Use ignored local overrides (`config/zsh/local.zsh` and `config/zsh/local.d/*.zsh`) for machine-specific shell settings and commands; do not put private/project-specific content in tracked shared modules.
- Prefer environment injection at runtime over static plaintext files.

## Reporting

If sensitive data is accidentally committed:

1. Revoke/rotate exposed credentials immediately.
2. Remove data from working tree and history as needed.
3. Open a security issue/notification to maintainers with impact details.

## Operational Constraints

- The Windows entrypoint manages host applications only; shell configuration is handled by the Debian/Ubuntu bootstrap inside WSL, not native Windows links.
- Keep project-specific shell modules and commands in ignored local overrides, never tracked shared config.
- Avoid adding scripts that exfiltrate environment variables or keychain values.
- Keep bootstrap network behavior within `brew`, `mise`, `uv`, `winget`, `apt-get`, `git`, and `curl`.
- Keep package ownership explicit: Homebrew for native applications, mise for declared runtimes/tools, uv for Python, winget for Windows host applications, and apt for Debian packages. Project dependencies remain project-local.
- Uninstall is not an ownership ledger: winget cannot prove an app was installed by this bootstrap. Remove only verified repository-owned links/config references, inspect backups before restoring, and select package removals individually; never delete regular user files or run broad cleanup without a reviewed preview.
