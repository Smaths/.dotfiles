# Prompt Purification (Vendored)

Vendored Prompt Purification keeps the Zsh prompt reproducible without a
bootstrap download. The only source change removes a trailing space for repo
validation.

- Upstream: <https://github.com/Phantas0s/purification>
- Vendored commit: `0faad169067d621c832a60e742179ac4124a45f5`
- Upstream Git blob: `903bc7910164a9be576ca70526e8e0d9b4dc5219`
- Vendored Git blob: `3b912f41672482c9c7da94ba930331182da799e8`
- Vendored SHA-256: `ddd07230cd83515990c5c51bcb25637ccf5676b9dd919cb7e4f4acf13aac8ab6`
- Author: Matthieu Cneude
- License: MIT, as declared by the upstream project

The source header also preserves attribution to Purity by Kevin Lanni.

To update the vendored prompt, review a specific upstream commit, replace
`prompt_purification_setup`, and update the commit, blob, and SHA-256 values in
this file plus the expected blob in `tests/check.sh`.
