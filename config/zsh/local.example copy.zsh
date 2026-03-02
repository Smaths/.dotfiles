# Copy this file to local.zsh for machine-specific, non-committed overrides.
# Example:
# export EDITOR="nvim"
# alias workvpn='open -a "My VPN"'

# Retrieve OpenAI API key from Keychain
export OPENAI_API_KEY=$(security find-generic-password -a "$USER" -s "openai-api-key" -w 2>/dev/null)