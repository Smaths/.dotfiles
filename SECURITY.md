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
- Use ignored local override files where needed (`config/zsh/local.zsh` pattern).
- Prefer environment injection at runtime over static plaintext files.

## Reporting

If sensitive data is accidentally committed:

1. Revoke/rotate exposed credentials immediately.
2. Remove data from working tree and history as needed.
3. Open a security issue/notification to maintainers with impact details.

## Operational Constraints

- Avoid adding scripts that exfiltrate environment variables or keychain values.
- Avoid broad network calls in bootstrap logic outside documented dependencies.
