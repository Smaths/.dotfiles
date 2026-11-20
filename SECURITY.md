# Security policy

## Secrets

Never commit tokens, private keys, credentials, passwords, or session cookies.
Use macOS Keychain or 1Password instead.

## Handling sensitive config

- Put private shell settings in ignored `config/zsh/local.zsh` or
  `config/zsh/local.d/*.zsh`, not tracked shared modules.
- Inject secrets at runtime rather than storing them in plaintext config.
- Keep Alfred's live `prefs.plist` out of the repo; it contains the selected
  vault and may hold other machine-specific settings.

## Reporting

If sensitive data is accidentally committed:

1. Revoke/rotate exposed credentials immediately.
2. Remove data from working tree and history as needed.
3. Open a security issue/notification to maintainers with impact details.

## Operational constraints

- Do not send environment variables or keychain values to third parties.
- Keep bootstrap network calls within `brew`, `mise`, `uv`, `winget`, `apt-get`,
  `git`, and `curl`.
- Package managers do not prove which apps bootstrap installed. Remove only
  verified repo-owned links or references, inspect backups before restoring,
  and review package removals individually. Preview broad cleanup; preserve
  regular user files. See [restore guidance](docs/OPERATIONS.md#restore).
