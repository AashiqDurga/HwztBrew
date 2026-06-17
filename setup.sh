#!/usr/bin/env bash
# =============================================================================
# setup.sh — one-command Mac setup (Apple Silicon, M-series).
#
#   Usage:   ./setup.sh
#
# Safe to re-run: every step checks before acting (idempotent). It will NOT
# overwrite your existing dotfiles — it backs them up first.
# =============================================================================

set -euo pipefail

# ---- pretty output ----------------------------------------------------------
BOLD="$(tput bold 2>/dev/null || true)"; RESET="$(tput sgr0 2>/dev/null || true)"
log()  { printf "\n%s==>%s %s\n" "$BOLD" "$RESET" "$1"; }
ok()   { printf "    \033[32m✓\033[0m %s\n" "$1"; }
skip() { printf "    \033[33m•\033[0m %s\n" "$1"; }

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$REPO_DIR/dotfiles"

# ---- 0. sanity checks -------------------------------------------------------
if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This script is for macOS only."; exit 1
fi

# ---- 0b. Admin access (ask once, up front) ---------------------------------
# Homebrew and some casks need sudo. Ask for the password once now and keep the
# sudo timestamp warm in the background, so the long install runs unattended
# instead of stopping to prompt you partway through.
SUDO_KEEPALIVE_PID=""
if [[ -t 0 ]]; then
  log "Admin access"
  echo "    You'll be asked for your Mac password once, now — then it's hands-off."
  echo "    (Do NOT run this whole script with sudo; just answer this prompt.)"
  if sudo -v; then
    ( while true; do sudo -n true; sleep 60; kill -0 "$$" 2>/dev/null || exit; done ) &
    SUDO_KEEPALIVE_PID=$!
    ok "authorized for this run"
  else
    skip "no sudo now — Homebrew may prompt you later"
  fi
fi
trap '[[ -n "$SUDO_KEEPALIVE_PID" ]] && kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true' EXIT

# ---- 1. Xcode Command Line Tools -------------------------------------------
log "Xcode Command Line Tools"
if xcode-select -p >/dev/null 2>&1; then
  skip "already installed"
else
  xcode-select --install 2>/dev/null || true
  echo "    A system dialog opened — click Install and accept the licence."
  echo "    Waiting for it to finish (this can take several minutes)…"
  until xcode-select -p >/dev/null 2>&1; do sleep 5; done
  ok "installed"
fi

# ---- 2. Homebrew ------------------------------------------------------------
log "Homebrew"
if ! command -v brew >/dev/null 2>&1; then
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  ok "installed"
else
  skip "already installed"
fi

# Put brew on PATH for this session (Apple Silicon lives in /opt/homebrew).
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

log "Updating Homebrew"
brew update >/dev/null && ok "up to date"

# ---- 2b. Trust third-party taps used by the Brewfile -----------------------
# Newer Homebrew refuses casks/formulae from untrusted third-party taps. The
# docker/tap tap provides the `sbx` (Docker Sandboxes) cask, so trust it before
# bundling. (`|| true` keeps this a no-op on older Homebrew without the gate.)
log "Trusting docker/tap (for sbx)"
brew tap docker/tap >/dev/null 2>&1 || true
brew trust docker/tap >/dev/null 2>&1 && ok "docker/tap trusted" || skip "brew trust unavailable (older Homebrew) — continuing"

# ---- 3. Install everything in the Brewfile ---------------------------------
log "Installing packages from Brewfile (this takes a while)"
# Don't let one failed/renamed package abort the whole setup — keep going so
# dotfiles, the sandbox, and macOS defaults still get applied. Re-run to retry.
if brew bundle --file="$REPO_DIR/Brewfile"; then
  ok "Brewfile complete"
else
  skip "some packages didn't install — continuing (re-run ./setup.sh to retry them)"
fi

# ---- 4. Language runtimes via mise -----------------------------------------
# mise installs and pins language versions. Edit the list to taste.
log "Language runtimes (mise)"
if command -v mise >/dev/null 2>&1; then
  mise use --global node@lts
  mise use --global python@latest
  # mise use --global go@latest
  # mise use --global rust@latest
  # mise use --global ruby@latest
  ok "node + python installed via mise"
else
  skip "mise not found — check the Brewfile"
fi

# ---- 4b. Oh My Zsh + plugins ------------------------------------------------
log "Oh My Zsh"
if [[ -d "$HOME/.oh-my-zsh" ]]; then
  skip "already installed"
else
  # Unattended: don't launch a new shell, don't touch our .zshrc.
  RUNZSH=no KEEP_ZSHRC=yes sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  ok "installed"
fi

# Custom plugins (autosuggestions + syntax highlighting) used by .zshrc.
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
clone_plugin() {
  local name="$1" url="$2" dir="$ZSH_CUSTOM/plugins/$1"
  if [[ -d "$dir" ]]; then
    git -C "$dir" pull --quiet || true; skip "$name (updated)"
  else
    git clone --depth=1 "$url" "$dir" >/dev/null 2>&1 && ok "$name"
  fi
}
clone_plugin zsh-autosuggestions     https://github.com/zsh-users/zsh-autosuggestions
clone_plugin zsh-syntax-highlighting https://github.com/zsh-users/zsh-syntax-highlighting

# ---- 5. Symlink dotfiles ----------------------------------------------------
log "Linking dotfiles"
link_dotfile() {
  local src="$DOTFILES_DIR/$1" dest="$HOME/$1"
  [[ -e "$src" ]] || { skip "$1 (none in repo)"; return; }
  if [[ -L "$dest" ]]; then
    ln -sfn "$src" "$dest"; ok "$1 (relinked)"
  elif [[ -e "$dest" ]]; then
    mv "$dest" "$dest.backup.$(date +%Y%m%d%H%M%S)"
    ln -s "$src" "$dest"; ok "$1 (existing backed up)"
  else
    ln -s "$src" "$dest"; ok "$1"
  fi
}
link_dotfile ".zshrc"
link_dotfile ".gitconfig"
link_dotfile ".aliases"

# ---- 5b. Claude Code sandbox -----------------------------------------------
log "Claude Code sandbox"
if [[ -f "$REPO_DIR/claude-code.sh" ]]; then
  bash "$REPO_DIR/claude-code.sh"
  ok "Claude Code sandbox configured"
fi

# ---- 6. macOS system defaults ----------------------------------------------
log "Applying macOS defaults"
if [[ -f "$REPO_DIR/macos.sh" ]]; then
  bash "$REPO_DIR/macos.sh"
  ok "macOS defaults applied"
fi

# ---- 7. Done ----------------------------------------------------------------
log "All done 🎉"
cat <<'EOF'

  Next steps:
    1. Restart your terminal (or run: exec zsh)
    2. Sign in to apps: 1Password, Slack, Chrome, Spotify…
    3. Authenticate GitHub:  gh auth login
    4. Claude Code sandbox:  sbx login, then run `claude` once to sign in.
       Start sandboxed project sessions with `ccx`  (see claude-sandbox/README.md)
    5. Some macOS tweaks need a logout/restart to fully apply.

EOF
