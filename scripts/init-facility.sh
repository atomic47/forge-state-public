#!/usr/bin/env bash
# init-facility.sh — create the forge facility at ~/forge (idempotent).
# No dot-directories: machinery lives in `state/`, not `.state/`.
set -euo pipefail

ROOT="${FORGE_ROOT:-$HOME/forge}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$HERE/.." && pwd)"

mkdir -p "$ROOT/experiments"
mkdir -p "$ROOT/state/logs"

# Manifest: copy template only if absent.
if [[ ! -f "$ROOT/manifest.yaml" ]]; then
  cp "$REPO_ROOT/templates/manifest.yaml.template" "$ROOT/manifest.yaml"
  echo "wrote: $ROOT/manifest.yaml"
else
  echo "exists: $ROOT/manifest.yaml (left as-is)"
fi

# state.json
if [[ ! -f "$ROOT/state/state.json" ]]; then
  cat > "$ROOT/state/state.json" <<'JSON'
{
  "counts_by_phase": {},
  "last_run": null,
  "last_cursor": {},
  "carry_forward": []
}
JSON
  echo "wrote: $ROOT/state/state.json"
else
  echo "exists: $ROOT/state/state.json (left as-is)"
fi

# activity.ndjson — touch empty
if [[ ! -f "$ROOT/state/activity.ndjson" ]]; then
  : > "$ROOT/state/activity.ndjson"
  echo "wrote: $ROOT/state/activity.ndjson"
else
  echo "exists: $ROOT/state/activity.ndjson (left as-is)"
fi

# cursor.yaml — empty mapping
if [[ ! -f "$ROOT/state/cursor.yaml" ]]; then
  echo '{}' > "$ROOT/state/cursor.yaml"
  echo "wrote: $ROOT/state/cursor.yaml"
else
  echo "exists: $ROOT/state/cursor.yaml (left as-is)"
fi

echo
echo "forge facility ready at: $ROOT"
