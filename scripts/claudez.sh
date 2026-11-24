# claudez: Claude Code through Surplus Intelligence (bash and zsh).
# Key: ~/.config/surplus/api_key (chmod 600).

unalias claudez surplus-balance 2>/dev/null

function claudez {
  local key_file="$HOME/.config/surplus/api_key"
  if [ ! -s "$key_file" ]; then
    echo "claudez: missing Surplus API key in $key_file" >&2
    echo "Get a key: https://www.surplusintelligence.ai/app/buy/quickstart" >&2
    return 1
  fi
  local key; key="$(cat "$key_file")"
  CLAUDE_CONFIG_DIR="$HOME/.claudez" \
  SURPLUS_BASE_URL="https://api.surplusintelligence.ai/v1" \
  ANTHROPIC_BASE_URL="https://api.surplusintelligence.ai/anthropic" \
  ANTHROPIC_AUTH_TOKEN="$key" \
  ANTHROPIC_API_KEY="" \
  SURPLUS_API_KEY="$key" \
  API_TIMEOUT_MS=3000000 \
  ANTHROPIC_MODEL='glm-5.3' \
  ANTHROPIC_SMALL_FAST_MODEL='glm-5.3' \
  ANTHROPIC_DEFAULT_OPUS_MODEL='glm-5.3' \
  ANTHROPIC_DEFAULT_SONNET_MODEL='glm-5.3' \
  ANTHROPIC_DEFAULT_HAIKU_MODEL='glm-5.3' \
  CLAUDE_CODE_SUBAGENT_MODEL='glm-5.3' \
  CLAUDE_CODE_AUTO_COMPACT_WINDOW=1000000 \
  CLAUDE_CODE_AUTO_MODE_SERVER=0 \
  CLAUDE_CODE_AUTO_MODE_MODEL='glm-5.3' \
  CLAUDE_CODE_ALWAYS_ENABLE_EFFORT=1 \
  ANTHROPIC_VISION_MODEL='qwen3.8-omni-flash' \
  SURPLUS_VISION_MODEL='qwen3.8-omni-flash' \
  ANTHROPIC_DEFAULT_OPUS_MODEL_NAME='GLM-5.3' \
  ANTHROPIC_DEFAULT_SONNET_MODEL_NAME='GLM-5.3' \
  ANTHROPIC_DEFAULT_HAIKU_MODEL_NAME='GLM-5.3' \
  ANTHROPIC_DEFAULT_OPUS_MODEL_DESCRIPTION='Surplus GLM-5.3, 1M context (same model as Sonnet)' \
  ANTHROPIC_DEFAULT_SONNET_MODEL_DESCRIPTION='Surplus GLM-5.3, 1M context' \
  ANTHROPIC_DEFAULT_HAIKU_MODEL_DESCRIPTION='Surplus GLM-5.3, used for background tasks' \
  CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1 \
    claude "$@"
}
