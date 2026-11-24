#!/usr/bin/env bash
# claudez installer for Linux and macOS.
# Sets up `claudez` with Surplus model routing and DuckDuckGo web search.
#
#   curl -fsSL https://raw.githubusercontent.com/yel-hadd/claude-code-zai/v1.3.0/install.sh | bash
#   ./install.sh [--no-mcp] [--ref TAG] | --uninstall [--purge]
#
# Non-interactive: SURPLUS_API_KEY=... ./install.sh
# https://github.com/yel-hadd/claude-code-zai
set -euo pipefail

REPO="yel-hadd/claude-code-zai"
REF="v1.3.0"
PLAN_URL="https://www.surplusintelligence.ai/app/buy/quickstart"
DEST="$HOME/.claudez"
KEY_FILE="$HOME/.config/surplus/api_key"
MARK_BEGIN="# >>> claudez >>>"
MARK_END="# <<< claudez <<<"
FILES="scripts/claudez.sh scripts/statusline.sh config/settings.json"
MCP_NAMES="duckduckgo-search"

action=do_install; purge=0; with_mcp=1
while [ $# -gt 0 ]; do
  case "$1" in
    --uninstall) action=do_uninstall ;;
    --purge) purge=1 ;;
    --no-mcp) with_mcp=0 ;;
    --ref) REF="$2"; shift ;;
    -h|--help) sed -n '2,10p' "$0" 2>/dev/null || true; exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
  shift
done

say()  { printf '\033[1m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[33mwarning:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[31merror:\033[0m %s\n' "$*" >&2; exit 1; }

# rc files to manage: existing ~/.bashrc and ~/.zshrc, plus the one for the login shell
rc_files() {
  local shell_name; shell_name="$(basename "${SHELL:-bash}")"
  local list=""
  [ -f "$HOME/.bashrc" ] && list="$list $HOME/.bashrc"
  [ -f "$HOME/.zshrc" ] && list="$list $HOME/.zshrc"
  case "$shell_name" in
    zsh) case "$list" in *"$HOME/.zshrc"*) ;; *) list="$list $HOME/.zshrc" ;; esac ;;
    bash)
      if [ "$(uname -s)" = Darwin ]; then
        list="$list $HOME/.bash_profile"   # macOS Terminal starts login shells
      else
        case "$list" in *"$HOME/.bashrc"*) ;; *) list="$list $HOME/.bashrc" ;; esac
      fi ;;
  esac
  echo "$list"
}

strip_block() {  # remove our marked block from file $1, in place
  [ -f "$1" ] || return 0
  grep -qF "$MARK_BEGIN" "$1" || return 0
  local tmp; tmp="$(mktemp)"
  awk -v b="$MARK_BEGIN" -v e="$MARK_END" '$0==b{skip=1;next} $0==e{skip=0;next} !skip' "$1" > "$tmp"
  cat "$tmp" > "$1"; rm -f "$tmp"
}

claudez_mcp() { CLAUDE_CONFIG_DIR="$DEST" claude "$@"; }

mcp_exists() {
  [ -f "$DEST/.claude.json" ] && jq -e --arg n "$1" '.mcpServers[$n] != null' "$DEST/.claude.json" >/dev/null 2>&1
}

do_uninstall() {
  say "Removing claudez"
  for rc in $HOME/.bashrc $HOME/.zshrc $HOME/.bash_profile; do
    if [ -f "$rc" ] && grep -qF "$MARK_BEGIN" "$rc"; then strip_block "$rc"; say "Cleaned $rc"; fi
  done
  if command -v claude >/dev/null; then
    for n in $MCP_NAMES; do mcp_exists "$n" && claudez_mcp mcp remove -s user "$n" >/dev/null 2>&1 && say "Removed MCP server $n"; done
  fi
  if [ -f "$DEST/settings.json" ] && command -v jq >/dev/null; then
    local tmp; tmp="$(mktemp)"
    jq '
      (if (.statusLine.command // "") | test("claudez/statusline") then del(.statusLine) else . end)
      |       (if .permissions.deny then .permissions.deny -= ["Read(~/.config/surplus/**)"] else . end)
    ' "$DEST/settings.json" > "$tmp" && mv "$tmp" "$DEST/settings.json"
    say "Cleaned $DEST/settings.json"
  fi
  rm -f "$DEST/claudez.sh" "$DEST/statusline.sh"
  if [ "$purge" = 1 ]; then rm -f "$KEY_FILE"; say "Deleted $KEY_FILE"; else say "Kept your key in $KEY_FILE (use --purge to delete it)"; fi
  say "Done. $DEST is kept because it holds your Claude Code history and settings."
}

do_install() {
  command -v curl >/dev/null || die "curl is required"
  command -v jq >/dev/null || die "jq is required. Install it first (Fedora: sudo dnf install jq, Debian/Ubuntu: sudo apt install jq, macOS: brew install jq)"
  command -v claude >/dev/null || warn "Claude Code not found. Install it: curl -fsSL https://claude.ai/install.sh | bash"

  # 1. key
  mkdir -p "$(dirname "$KEY_FILE")"
  if [ -n "${SURPLUS_API_KEY:-}" ]; then
    (umask 077; printf '%s' "$SURPLUS_API_KEY" > "$KEY_FILE")
    say "Saved key from SURPLUS_API_KEY to $KEY_FILE"
  elif [ -s "$KEY_FILE" ]; then
    say "Using existing key in $KEY_FILE"
  else
    [ -r /dev/tty ] || die "No terminal to ask for the key. Run with SURPLUS_API_KEY=... set."
    printf 'Get a Surplus API key here:\n  %s\n' "$PLAN_URL" > /dev/tty
    printf 'Paste your Surplus API key (input hidden): ' > /dev/tty
    local key; IFS= read -rs key < /dev/tty; echo > /dev/tty
    key="$(printf '%s' "$key" | tr -d '[:space:]')"
    [ -n "$key" ] || die "No key entered. Get a Surplus API key at $PLAN_URL"
    (umask 077; printf '%s' "$key" > "$KEY_FILE")
    say "Saved key to $KEY_FILE"
  fi
  chmod 600 "$KEY_FILE"

  # 2. files: from this clone if we are in one, else from GitHub at $REF
  local src="" here
  # shellcheck disable=SC2015
  here="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || true)"
  [ -n "$here" ] && [ -f "$here/scripts/claudez.sh" ] && src="$here"
  stage="$(mktemp -d)"
  trap 'rm -rf "$stage"' EXIT
  for f in $FILES; do
    mkdir -p "$stage/$(dirname "$f")"
    if [ -n "$src" ]; then cp "$src/$f" "$stage/$f"
    else curl -fsSL "https://raw.githubusercontent.com/$REPO/$REF/$f" -o "$stage/$f" || die "Download failed: $f"
    fi
  done
  say "Installing scripts from ${src:-github.com/$REPO@$REF} into $DEST"
  mkdir -p "$DEST"
  install -m 755 "$stage/scripts/statusline.sh" "$DEST/"
  install -m 755 "$stage/scripts/claudez.sh" "$DEST/"

  # 3. settings: merge, keeping whatever is already there
  local settings="$DEST/settings.json" tmp; tmp="$(mktemp)"
  [ -s "$settings" ] || echo '{}' > "$settings"
  cp "$settings" "$settings.bak.claudez"
  jq --slurpfile t "$stage/config/settings.json" '
    $t[0] as $t
    | .permissions.deny = (((.permissions.deny // []) + $t.permissions.deny) | unique)
    | (if (.statusLine == null) or ((.statusLine.command // "") | test("claudez/statusline"))
       then .statusLine = $t.statusLine else . end)
  ' "$settings" > "$tmp" && mv "$tmp" "$settings"
  if ! jq -e '(.statusLine.command // "") | test("claudez/statusline")' "$settings" >/dev/null; then
    warn "Kept your existing statusLine in $settings; the Surplus status line was not enabled"
  fi
  say "Merged settings into $settings (backup: $settings.bak.claudez)"

  # 4. shell rc block
  for rc in $(rc_files); do
    [ -f "$rc" ] && cp "$rc" "$rc.bak.claudez"
    strip_block "$rc"
    # start on a fresh line, or the marker gets glued to the file's last line
    if [ -s "$rc" ] && [ -n "$(tail -c1 "$rc")" ]; then echo >> "$rc"; fi
    {
      echo "$MARK_BEGIN"
      echo '# claudez: Claude Code through Surplus Intelligence.'
      # shellcheck disable=SC2016
      echo '[ -f "$HOME/.claudez/claudez.sh" ] && . "$HOME/.claudez/claudez.sh"'
      echo "$MARK_END"
    } >> "$rc"
    say "Added claudez to $rc"
  done

  # 5. Free DuckDuckGo web search MCP; no third-party API key required.
  if [ "$with_mcp" = 1 ] && command -v claude >/dev/null; then
    mcp_exists duckduckgo-search || claudez_mcp mcp add -s user duckduckgo-search \
      -- npx -y duckduckgo-websearch >/dev/null
    say "MCP servers ready: $MCP_NAMES"
  fi

  # 6. checks
  if command -v node >/dev/null; then
    local major; major="$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null || echo 0)"
    [ "$major" -ge 22 ] || warn "Node.js $major found; Claude Code MCP tools need Node.js 22 or newer"
  else
    warn "Node.js not found; the DuckDuckGo web search MCP needs Node.js"
  fi
  echo
  say "Installed. Open a new terminal (or source your shell rc), then run: claudez"
}

"$action"
