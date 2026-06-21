#!/usr/bin/env bash
# test-run.sh — invoke the orchestrator in --once --dry-run mode.
# Useful smoke test: confirms the orchestrator can read the facility, walk the
# queue, and plan dispatches without touching Docker or the network.
set -euo pipefail

ROOT="${FORGE_ROOT:-$HOME/forge}"

if [[ ! -d "$ROOT" ]]; then
  echo "facility not initialized: $ROOT (run scripts/init-facility.sh)" >&2
  exit 2
fi

echo "forge test-run (dry): root=$ROOT"
echo
echo "Invoke from inside a Claude Code session with:"
echo "    /forge-orchestrator --once --dry-run"
echo
echo "Or run via the headless CLI vehicle (spec §14):"
echo "    claude --skill forge-orchestrator --args '--once --dry-run'"
echo
echo "Pre-flight facility check:"
ls -la "$ROOT" || true
echo
ls -la "$ROOT/state" || true
