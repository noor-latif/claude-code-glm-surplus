# Claude Code with Surplus Intelligence

Run Claude Code through [Surplus Intelligence](https://www.surplusintelligence.ai/) on Linux or Windows.

- Public Surplus base URL: `https://api.surplusintelligence.ai/v1`
- Claude Code protocol URL: `https://api.surplusintelligence.ai/anthropic`
- Main, Sonnet, Opus, Haiku, and subagent model: `glm-5.3[1m]`
- Vision model: `qwen3.8-omni-flash`
- Web search: free DuckDuckGo MCP server; no Surplus quota or search key required
- Separate config: `~/.claudez`

## Install on Linux or macOS

```bash
SURPLUS_API_KEY='inf_...' ./install.sh
```

The installer requires `curl`, `jq`, and Node.js for MCP tools. It stores the key at `~/.config/surplus/api_key` with user-only permissions.

To inspect or change the key interactively:

```bash
./install.sh
```

## Install on Windows

Run in PowerShell:

```powershell
$env:SURPLUS_API_KEY = 'inf_...'
.\install.ps1
```

The key is stored at `$HOME\.config\surplus\api_key` and the Windows profile is configured for PowerShell 5.1 and 7.

## Run

Open a new terminal and run:

```bash
claudez
```

The launcher blanks `ANTHROPIC_API_KEY` and uses `ANTHROPIC_AUTH_TOKEN` so Claude Code authenticates with Surplus rather than a cached Claude login.

To reinstall or update:

```bash
./install.sh --no-mcp
.\install.ps1 -NoMcp
```

To remove the launcher and MCP server:

```bash
./install.sh --uninstall --purge
.\install.ps1 -Uninstall -Purge
```

## Model configuration

| Claude role | Surplus model |
|---|---|
| Main, Opus, Sonnet, Haiku | `glm-5.3[1m]` |
| Subagent and auto mode | `glm-5.3[1m]` |
| Vision | `qwen3.8-omni-flash` |

## Web search

The installer registers the `duckduckgo-search` MCP server through `npx`. It uses DuckDuckGo and does not require a separate API key.

## API endpoints

- OpenAI-compatible: `https://api.surplusintelligence.ai/v1`
- Claude/Anthropic Messages: `https://api.surplusintelligence.ai/anthropic`
- Model catalog: `https://api.surplusintelligence.ai/v1/models`

## Uninstall

The installers remove shell/profile blocks and the `duckduckgo-search` MCP entry. `--purge` / `-Purge` also deletes the stored key.

## Tests

Run the provider smoke tests against a real Surplus account:

```bash
SURPLUS_API_KEY='inf_...' python3 tests/surplus_smoke.py
```

The test validates the model catalog, GLM text routing, and Qwen vision routing using a public fixed-color PNG.
