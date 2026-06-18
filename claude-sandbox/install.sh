#!/usr/bin/env bash
# =============================================================================
# install.sh — self-serve installer for JUST the Claude Code sandbox.
#
# No Mac bootstrap, no dotfiles, no Brewfile — only the sandboxed Claude Code
# setup: the always-on Bash sandbox (Tier 1) + the per-project Docker Sandbox
# `ccx` command (Tier 3). Use this if you just want to sandbox Claude Code on a
# machine you already use.
#
#   git clone https://github.com/AashiqDurga/HwztBrew.git
#   cd HwztBrew && ./claude-sandbox/install.sh
#
# Requires Homebrew (https://brew.sh). macOS only. Safe to re-run.
# =============================================================================
set -euo pipefail

BOLD="$(tput bold 2>/dev/null || true)"; RESET="$(tput sgr0 2>/dev/null || true)"
log()  { printf "\n%s==>%s %s\n" "$BOLD" "$RESET" "$1"; }
ok()   { printf "    \033[32m✓\033[0m %s\n" "$1"; }
skip() { printf "    \033[33m•\033[0m %s\n" "$1"; }

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

[[ "$(uname -s)" == "Darwin" ]] || { echo "macOS only — the Bash sandbox needs Seatbelt."; exit 1; }

# ---- Homebrew (required) ----------------------------------------------------
if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew is required. Install it from https://brew.sh, then re-run this." >&2
  exit 1
fi
eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || true)"

# ---- CLIs -------------------------------------------------------------------
log "Claude Code CLI"
if command -v claude >/dev/null 2>&1; then skip "already installed"
else brew install --cask claude-code && ok "installed"; fi

log "Docker Sandboxes (sbx)"
if command -v sbx >/dev/null 2>&1; then
  skip "already installed"
else
  # docker/tap is a third-party tap; newer Homebrew requires explicit trust.
  brew tap docker/tap >/dev/null 2>&1 || true
  brew trust docker/tap >/dev/null 2>&1 || true
  brew install --cask sbx && ok "installed"
fi

log "jq (used to merge settings)"
if command -v jq >/dev/null 2>&1; then skip "already installed"
else brew install jq && ok "installed"; fi

# ---- Sandbox config + kit + status line + ccx -------------------------------
# claude-code.sh writes ~/.claude/settings.json (Tier-1 Bash sandbox), installs
# the status line, and copies the kit (incl. ccx.sh) to ~/.config/claude-sandbox/.
log "Sandbox config + kit"
bash "$REPO_DIR/claude-code.sh"

# ---- Wire `ccx` into your shell --------------------------------------------
log "Shell function (ccx)"
CCX_SRC="$HOME/.config/claude-sandbox/ccx.sh"
RC="$HOME/.zshrc"; [[ "${SHELL:-}" == *bash ]] && RC="$HOME/.bashrc"
if [[ -f "$CCX_SRC" ]]; then
  if grep -qF "claude-sandbox/ccx.sh" "$RC" 2>/dev/null; then
    skip "ccx already wired into ${RC/#$HOME/~}"
  else
    printf '\n# Claude Code sandbox — the `ccx` command\n[ -f "%s" ] && source "%s"\n' "$CCX_SRC" "$CCX_SRC" >> "$RC"
    ok "added ccx to ${RC/#$HOME/~}"
  fi
else
  skip "ccx.sh not found (claude-code.sh should have installed it)"
fi

cat <<EOF

  $(printf '%s' "${BOLD}")Done — Claude Code sandbox installed.${RESET} Next steps:

    1. Restart your terminal     (or: exec \$SHELL)
    2. sbx login                 # sign in to Docker Sandboxes (free Docker account)
    3. bash $REPO_DIR/claude-sandbox/policy.sh   # set the 'balanced' network policy
    4. cd <a project> && ccx     # autonomous Claude in a per-project microVM

  How it works + the per-project workflow:
    $REPO_DIR/claude-sandbox/README.md

EOF
