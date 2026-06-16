#!/usr/bin/env bash
# =============================================================================
# claude-code.sh — Claude Code sandbox config for this Mac.
#
#   Usage:   ./claude-code.sh
#
# Installs nothing: the `claude-code` CLI and the `sbx` (Docker Sandboxes) CLI
# both come from the Brewfile. This script just writes the always-on Bash
# sandbox settings into ~/.claude/settings.json, merging with any existing
# file (and backing it up first). Safe to re-run.
#
# Two isolation layers result (see claude-sandbox/README.md):
#   • Bash sandbox  — every host `claude` session, via ~/.claude/settings.json
#   • Docker Sandbox — per-project microVM, started with the `ccx` shell command
# =============================================================================

set -euo pipefail

# ---- pretty output (matches setup.sh / macos.sh) ---------------------------
BOLD="$(tput bold 2>/dev/null || true)"; RESET="$(tput sgr0 2>/dev/null || true)"
log()  { printf "\n%s==>%s %s\n" "$BOLD" "$RESET" "$1"; }
ok()   { printf "    \033[32m✓\033[0m %s\n" "$1"; }
skip() { printf "    \033[33m•\033[0m %s\n" "$1"; }

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$REPO_DIR/claude/settings.json"
DEST_DIR="$HOME/.claude"
DEST="$DEST_DIR/settings.json"

log "Claude Code sandbox settings"

# The `claude-code` cask provides the CLI. Warn (don't fail) if it isn't here
# yet — e.g. when running this script standalone before `brew bundle`.
command -v claude >/dev/null 2>&1 \
  || skip 'claude CLI not found yet — it installs via the Brewfile (cask "claude-code")'

# jq is in the Brewfile and is installed before this step in setup.sh. Without
# it we can't safely merge, so bail gracefully rather than clobber settings.
if ! command -v jq >/dev/null 2>&1; then
  skip "jq not found — install it (it's in the Brewfile), then re-run this script"
  exit 0
fi

mkdir -p "$DEST_DIR"

if [[ -f "$DEST" ]]; then
  # Deep-merge our sandbox block into existing settings, keeping other keys
  # (model, theme, hooks, …). Arrays under `sandbox` are replaced by ours.
  backup="$DEST.backup.$(date +%Y%m%d%H%M%S)"
  cp "$DEST" "$backup"
  tmp="$(mktemp)"
  jq -s '.[0] * .[1]' "$DEST" "$SRC" > "$tmp"
  mv "$tmp" "$DEST"
  ok "merged sandbox config into ~/.claude/settings.json (backup: $(basename "$backup"))"
else
  cp "$SRC" "$DEST"
  ok "wrote ~/.claude/settings.json"
fi

# ---- Install the Docker Sandbox kit to a stable global path -----------------
# `ccx` (in .aliases) points `sbx run --kit` here when a project has no local
# ./claude-sandbox/ of its own — so every project gets the same kit (tooling,
# MCP servers, plugins, network allowlist) without copying anything in.
KIT_SRC="$REPO_DIR/claude-sandbox"
KIT_DEST="$HOME/.config/claude-sandbox"
if [[ -d "$KIT_SRC" ]]; then
  mkdir -p "$HOME/.config"
  rm -rf "$KIT_DEST"
  cp -R "$KIT_SRC" "$KIT_DEST"
  ok "installed sandbox kit → ~/.config/claude-sandbox"
fi

cat <<'EOF'

    Sandbox layers configured:
      • Bash sandbox (always-on)  — wraps every host `claude` session
      • Docker Sandbox (default)  — start project sessions with:  ccx

    One-time manual steps (these need your login, so can't be scripted):
      1. sbx login            # authenticate Docker Sandboxes
      2. claude               # sign in to Claude Code once
      3. claude setup-token   # optional: long-lived token to reuse inside sandboxes

    See claude-sandbox/README.md for the per-project workflow.
EOF
