# =============================================================================
# ccx.sh — the `ccx` shell function.
#
# Runs Claude Code inside a per-project Docker Sandbox microVM, fully
# autonomous. Single source of truth: claude-code.sh installs this to
# ~/.config/claude-sandbox/ccx.sh; both the dotfiles and the standalone
# installer source it from there.
#
# Source it from your shell rc (zsh or bash):
#     [ -f ~/.config/claude-sandbox/ccx.sh ] && source ~/.config/claude-sandbox/ccx.sh
#
#   `claude` = raw host binary (still wrapped by the always-on Bash sandbox via
#              ~/.claude/settings.json; permission prompts stay on).
#   `ccx`    = start a session inside a per-project Docker Sandbox microVM,
#              FULLY AUTONOMOUS (--dangerously-skip-permissions). The VM is the
#              safety boundary, so Claude just works — it can't reach anything
#              outside the mounted project + allowed domains.
#
# Named after the git repo so re-running reuses the same sandbox. Args pass
# through, e.g. `ccx --continue`. Set CCX_PROMPT=1 to keep prompts for one run.
# =============================================================================
ccx() {
  command -v sbx >/dev/null 2>&1 || {
    echo "sbx not installed — run: brew install docker/tap/sbx" >&2; return 1
  }
  # Make sure we're signed in to Docker Sandboxes first — otherwise `sbx run`
  # dies with a raw 401. Sign in once if needed.
  if sbx ls 2>&1 | grep -qiE 'not authenticated|sign in to docker|no valid user session'; then
    echo "ccx: not signed in to Docker Sandboxes — opening login…" >&2
    sbx login || { echo "ccx: sbx login failed" >&2; return 1; }
  fi
  local root name kit
  root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  name="$(basename "$root")"
  # Apply the kit (tooling + MCP servers + plugins + network allowlist):
  # a project-local one if present, else the global default that setup installs.
  if [[ -f "$root/claude-sandbox/spec.yaml" ]]; then
    kit="$root/claude-sandbox"
  elif [[ -f "$HOME/.config/claude-sandbox/spec.yaml" ]]; then
    kit="$HOME/.config/claude-sandbox"
  fi
  local kitarg=(); [[ -n "$kit" ]] && kitarg=(--kit "$kit")
  local perm=(--dangerously-skip-permissions)
  [[ -n "${CCX_PROMPT:-}" ]] && perm=()
  # sbx grammar (verified via `sbx run --help`):
  #   sbx run [flags] AGENT [PATH...] [-- AGENT_ARGS...]
  # Workspace defaults to the current dir; AGENT args go AFTER the `--`.
  local agentargs=("${perm[@]}" "$@")
  if (( ${#agentargs[@]} )); then
    ( builtin cd "$root" && sbx run "${kitarg[@]}" --name "$name" claude -- "${agentargs[@]}" )
  else
    ( builtin cd "$root" && sbx run "${kitarg[@]}" --name "$name" claude )
  fi
}
