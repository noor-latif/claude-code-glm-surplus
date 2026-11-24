# Surplus setup prompt

Set up Claude Code with Surplus Intelligence from this repository.

1. Ask for a Surplus API key beginning with `inf_`. Link to `https://www.surplusintelligence.ai/app/buy/quickstart` if needed.
2. Run `SURPLUS_API_KEY='<key>' ./install.sh` on Linux/macOS or `$env:SURPLUS_API_KEY='<key>'; .\install.ps1` on Windows.
3. Verify `claudez` is installed and launch it once.
4. Confirm the launcher uses:
   - `SURPLUS_BASE_URL=https://api.surplusintelligence.ai/v1`
   - `ANTHROPIC_BASE_URL=https://api.surplusintelligence.ai/anthropic`
   - `glm-5.3[1m]` for Claude roles
   - `qwen3.8-omni-flash` for vision
5. Confirm DuckDuckGo web search is registered as the `duckduckgo-search` MCP server.
