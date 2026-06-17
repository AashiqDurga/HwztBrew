#!/usr/bin/env bash
# =============================================================================
# statusline.sh — Claude Code status line.
#
# Installed to ~/.claude/statusline.sh by claude-code.sh and referenced from
# settings.json `statusLine`. Reads Claude Code's status JSON on stdin and
# prints one line: an env tag (host vs ccx sandbox) · model · repo · a context
# usage bar · and a motivational quote that rotates daily.
# =============================================================================

input="$(cat)"

model="Claude"; dir="$PWD"; pct=0; repo=""
if command -v jq >/dev/null 2>&1; then
  model="$(printf '%s' "$input" | jq -r '.model.display_name // "Claude"')"
  dir="$(printf  '%s' "$input" | jq -r '.workspace.current_dir // "."')"
  pct="$(printf  '%s' "$input" | jq -r '(.context_window.used_percentage // 0) | floor')"
  repo="$(printf '%s' "$input" | jq -r '.workspace.repo.name // empty')"
fi

# 5-cell context bar
filled=$(( pct / 20 )); [ "$filled" -gt 5 ] && filled=5
bar=""; for i in 1 2 3 4 5; do [ "$i" -le "$filled" ] && bar="${bar}▓" || bar="${bar}░"; done

# host vs sandbox — the kit drops ~/.ccx-sandbox inside the microVM
if [ -f "$HOME/.ccx-sandbox" ] || [ -n "${CCX_SANDBOX:-}" ]; then
  tag="🦀 ccx sandbox"
else
  tag="💻 host"
fi

# Motivational quote — rotates daily (stable within a day). 10# forces base-10
# so a zero-padded day-of-year (e.g. 008) isn't read as octal.
quotes=(
  "Make it work, make it right, make it fast."
  "First, solve the problem. Then, write the code."
  "Simplicity is the soul of efficiency."
  "Weeks of coding can save you hours of planning."
  "The best error message is the one that never shows up."
  "Programs must be written for people to read."
  "Talk is cheap. Show me the code."
)
idx=$(( 10#$(date +%j) % ${#quotes[@]} ))
quote="${quotes[$idx]}"

printf '%s · %s%s · %s %s%% · "%s"' \
  "$tag" "$model" "${repo:+  ⎇ $repo}" "$bar" "$pct" "$quote"
