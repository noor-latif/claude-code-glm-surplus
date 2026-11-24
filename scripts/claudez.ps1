# claudez: Claude Code through Surplus Intelligence (PowerShell 5.1 and 7).
# Key: ~/.config/surplus/api_key (owner-only ACL).

function claudez {
  $keyFile = Join-Path $HOME '.config\surplus\api_key'
  if (-not (Test-Path $keyFile) -or -not "$(Get-Content $keyFile -Raw)".Trim()) {
    Write-Host "Get a key: https://www.surplusintelligence.ai/app/buy/quickstart"
    Write-Error "claudez: missing Surplus API key in $keyFile"; return
  }
  $key = (Get-Content $keyFile -Raw).Trim()
  $vars = @{
    CLAUDE_CONFIG_DIR                        = Join-Path $HOME '.claudez'
    SURPLUS_BASE_URL                         = 'https://api.surplusintelligence.ai/v1'
    ANTHROPIC_BASE_URL                       = 'https://api.surplusintelligence.ai/anthropic'
    ANTHROPIC_AUTH_TOKEN                     = $key
    ANTHROPIC_API_KEY                        = ''
    SURPLUS_API_KEY                          = $key
    API_TIMEOUT_MS                           = '3000000'
    ANTHROPIC_MODEL                          = 'glm-5.3'
    ANTHROPIC_SMALL_FAST_MODEL               = 'glm-5.3'
    ANTHROPIC_DEFAULT_OPUS_MODEL             = 'glm-5.3'
    ANTHROPIC_DEFAULT_SONNET_MODEL           = 'glm-5.3'
    ANTHROPIC_DEFAULT_HAIKU_MODEL            = 'glm-5.3'
    CLAUDE_CODE_SUBAGENT_MODEL               = 'glm-5.3'
    CLAUDE_CODE_AUTO_COMPACT_WINDOW          = '1000000'
    CLAUDE_CODE_AUTO_MODE_SERVER             = '0'
    CLAUDE_CODE_AUTO_MODE_MODEL              = 'glm-5.3'
    CLAUDE_CODE_ALWAYS_ENABLE_EFFORT         = '1'
    ANTHROPIC_VISION_MODEL                   = 'qwen3.8-omni-flash'
    SURPLUS_VISION_MODEL                     = 'qwen3.8-omni-flash'
    ANTHROPIC_DEFAULT_OPUS_MODEL_NAME        = 'GLM-5.3'
    ANTHROPIC_DEFAULT_SONNET_MODEL_NAME      = 'GLM-5.3'
    ANTHROPIC_DEFAULT_HAIKU_MODEL_NAME       = 'GLM-5.3'
    ANTHROPIC_DEFAULT_OPUS_MODEL_DESCRIPTION   = 'Surplus GLM-5.3, 1M context (same model as Sonnet)'
    ANTHROPIC_DEFAULT_SONNET_MODEL_DESCRIPTION = 'Surplus GLM-5.3, 1M context'
    ANTHROPIC_DEFAULT_HAIKU_MODEL_DESCRIPTION  = 'Surplus GLM-5.3, used for background tasks'
    CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = '1'
  }
  $saved = @{}
  foreach ($name in $vars.Keys) {
    $saved[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
    [Environment]::SetEnvironmentVariable($name, $vars[$name], 'Process')
  }
  try { claude @args }
  finally {
    foreach ($name in $saved.Keys) {
      [Environment]::SetEnvironmentVariable($name, $saved[$name], 'Process')
    }
  }
}
