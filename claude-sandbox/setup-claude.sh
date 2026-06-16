#!/usr/bin/env bash
# =============================================================================
# setup-claude.sh — replicate the host's Claude Code MCP servers + plugins
# INSIDE a Docker Sandbox.
#
# Run ONCE per project sandbox (the named sandbox persists the result, so you
# won't need to run it again for that project):
#
#     bash claude-sandbox/setup-claude.sh
#
# The kit (kit.yaml) also tries to run this at sandbox creation; this script is
# the reliable manual fallback if that timing doesn't line up.
#
# Idempotent and SECRET-FREE: the remote MCP servers use OAuth — you authorize
# each once on first use (`claude` will prompt), and the named sandbox keeps
# that authorization. Mirrors the host config captured during setup.
# =============================================================================
set -euo pipefail

say() { printf "\n\033[1m==>\033[0m %s\n" "$1"; }
ok()  { printf "    \033[32m✓\033[0m %s\n" "$1"; }
note(){ printf "    \033[33m•\033[0m %s\n" "$1"; }

command -v claude >/dev/null 2>&1 || {
  echo "claude CLI not found — start the session with 'sbx run … claude' first, then re-run this." >&2
  exit 1
}

# ---- Plugins ----------------------------------------------------------------
# All from the official marketplace (anthropics/claude-plugins-official), which
# ships with Claude Code — no marketplace add needed.
say "Installing plugins"
PLUGINS=(
  claude-md-management
  frontend-design
  context7            # also supplies the context7 MCP server (so it's not re-added below)
  superpowers
  feature-dev
  code-simplifier
  ralph-loop
  playwright          # needs browser deps in the image to actually drive a browser
  security-guidance
  serena              # supplies the serena MCP server
)
for p in "${PLUGINS[@]}"; do
  if claude plugin install "${p}@claude-plugins-official" --scope user >/dev/null 2>&1; then
    ok "$p"
  else
    note "$p (already installed or unavailable)"
  fi
done

# vercel-plugin is NOT installed here: on the host its marketplace was added from
# a LOCAL directory, so there's no public source to reproduce. The Vercel MCP
# server below covers Vercel access. To get the plugin's skills/subagents too,
# add its real public marketplace source manually, then:
#     claude plugin install vercel-plugin@<marketplace> --scope user

# ---- MCP servers (user scope → every session in this sandbox sees them) ------
# Remote (http) servers authenticate via OAuth on first use; nothing is stored
# here. context7 + serena are intentionally omitted (their plugins provide them).
say "Adding MCP servers"
add_http() {
  if claude mcp add --scope user --transport http "$1" "$2" >/dev/null 2>&1; then
    ok "$1"; else note "$1 (already configured)"; fi
}
add_http supabase      https://mcp.supabase.com/mcp
add_http vercel        https://mcp.vercel.com
add_http clerk         https://mcp.clerk.com/mcp
add_http linear-server https://mcp.linear.app/mcp
add_http notion        https://mcp.notion.com/mcp

# trigger.dev — stdio server (launched via npx; needs node in the sandbox).
if claude mcp add --scope user trigger -- npx trigger.dev@4.4.3 mcp >/dev/null 2>&1; then
  ok "trigger"; else note "trigger (already configured)"; fi

cat <<'EOF'

    Done. First time only: run `claude` and authorize each remote MCP server
    when prompted (supabase, vercel, clerk, linear, notion). This sandbox is
    named + persistent, so you won't be asked again for this project.

    Tune the lists above to taste — trim servers/plugins you don't want in a
    given project.
EOF
