#!/usr/bin/env bash
# =============================================================================
# bootstrap.sh — zero-dependency entry point for a brand-new Mac.
#
# Needs ONLY curl (ships with macOS). No git required — it downloads the repo
# as a tarball, then hands off to setup.sh.
#
#   Run on a fresh Mac:
#     curl -fsSL https://raw.githubusercontent.com/USER/mac-setup/main/bootstrap.sh | bash
#
# Edit the two variables below to point at your repo.
# =============================================================================

set -euo pipefail

GITHUB_USER="AashiqDurga"
REPO="HwztBrew"
BRANCH="main"
DEST="$HOME/$REPO"

BOLD="$(tput bold 2>/dev/null || true)"; RESET="$(tput sgr0 2>/dev/null || true)"
log() { printf "\n%s==>%s %s\n" "$BOLD" "$RESET" "$1"; }

log "Downloading $GITHUB_USER/$REPO ($BRANCH) — no git needed"
tmp="$(mktemp -d)"
url="https://codeload.github.com/$GITHUB_USER/$REPO/tar.gz/refs/heads/$BRANCH"

# curl is preinstalled on macOS; -L follows redirects, -f fails on HTTP errors.
curl -fsSL "$url" | tar -xz -C "$tmp"

# The tarball extracts to <repo>-<branch>/ ; move it into place.
src="$tmp/$REPO-$BRANCH"
if [[ -d "$DEST" ]]; then
  log "Updating existing $DEST"
  cp -R "$src/." "$DEST/"
else
  mv "$src" "$DEST"
fi
rm -rf "$tmp"

log "Running setup"
cd "$DEST"
chmod +x setup.sh macos.sh claude-code.sh
exec ./setup.sh
