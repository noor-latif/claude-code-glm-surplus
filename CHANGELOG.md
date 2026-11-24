# Changelog

## 2026-11-25

- Fixed `glm-5.3[1m]` model id: Surplus rejects the `[1m]` suffix ("No available sellers") on direct API calls. All roles now use `glm-5.3`, which the catalog already serves with 1M context; `CLAUDE_CODE_AUTO_COMPACT_WINDOW=1000000` still pins the 1M window.
- Stopped the `[claude-code:unrecognized_model]` warning Claude Code prints for non-Anthropic model ids: the installers now merge `modelOverrides` (`"claude-sonnet-4-6": "glm-5.3"`) into `~/.claudez/settings.json`, which lets Claude Code resolve `glm-5.3` to a known model.
- Fixed flaky smoke tests: Surplus GLM counts thinking tokens against `max_tokens`, so small budgets truncated replies mid-token. Tests now send `thinking: {"type": "disabled"}` and the vision check gets a 256-token budget.

## 2026-11-24

- Migrated provider configuration to Surplus Intelligence.
- Added Linux and Windows `claudez` launchers with the Surplus API key.
- Mapped all Claude model roles to `glm-5.3` (1M context from the model catalog; the compact window is pinned separately).
- Set vision to `qwen3.8-omni-flash`.
- Replaced provider search/reader/vision MCP integrations with a keyless DuckDuckGo web search MCP.
- Added optional live Surplus tests for model catalog, text routing, and Qwen vision routing.
