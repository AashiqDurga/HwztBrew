#!/usr/bin/env bash
# =============================================================================
# policy.sh — preconfigure the sbx (Docker Sandboxes) network policy.
#
# Run ONCE per machine, AFTER `sbx login` and BEFORE your first sandbox. It sets
# the recommended "balanced" baseline non-interactively (default-deny + common
# dev sites allowed: AI services, package registries, …), so you skip the
# first-run prompt and get the same policy on every machine.
#
#   bash claude-sandbox/policy.sh
#
# This is the MACHINE baseline. Per-project egress is tightened separately in
# spec.yaml (network.allowedDomains); the two layer, and deny wins over allow.
# =============================================================================
set -euo pipefail

command -v sbx >/dev/null 2>&1 || {
  echo "sbx not installed — run: brew install docker/tap/sbx" >&2; exit 1
}

echo "Setting default network policy to 'balanced'…"
if sbx policy set-default balanced 2>/dev/null; then
  echo "  ✓ balanced — default-deny, with common dev sites (AI services, registries) allowed"
else
  echo "  • a default is already set (a sandbox was started, or you chose one at the prompt)."
  echo "    To change it:  sbx policy reset && bash claude-sandbox/policy.sh"
fi

# --- Global allow rules — hosts reachable from EVERY sandbox ------------------
# Add hosts you always want allowed machine-wide. Project-specific hosts belong
# in spec.yaml's network.allowedDomains instead, not here.
#   sbx policy allow network api.example.com:443

echo
echo "Inspect the active rules with:  sbx policy ls"
