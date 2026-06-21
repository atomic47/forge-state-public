#!/usr/bin/env bash
# validate.sh — walk ~/forge/experiments/*/experiment.yaml and validate each
# against schemas/experiment.schema.yaml. Pure bash + python3 (PyYAML, jsonschema).
set -euo pipefail

ROOT="${FORGE_ROOT:-$HOME/forge}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCHEMA="$(cd "$HERE/.." && pwd)/schemas/experiment.schema.yaml"
MANIFEST_SCHEMA="$(cd "$HERE/.." && pwd)/schemas/manifest.schema.yaml"

if [[ ! -d "$ROOT" ]]; then
  echo "facility not initialized: $ROOT (run init-facility.sh)" >&2
  exit 2
fi

python3 - "$ROOT" "$SCHEMA" "$MANIFEST_SCHEMA" <<'PY'
import sys, os, glob, json
try:
    import yaml
except ImportError:
    print("missing dep: pip install pyyaml", file=sys.stderr); sys.exit(3)
try:
    import jsonschema
except ImportError:
    print("missing dep: pip install jsonschema", file=sys.stderr); sys.exit(3)

root, schema_path, manifest_schema_path = sys.argv[1], sys.argv[2], sys.argv[3]
with open(schema_path) as f: exp_schema = yaml.safe_load(f)
with open(manifest_schema_path) as f: man_schema = yaml.safe_load(f)

errors = 0
total  = 0

# Validate manifest
mpath = os.path.join(root, "manifest.yaml")
if os.path.exists(mpath):
    with open(mpath) as f: doc = yaml.safe_load(f)
    try:
        jsonschema.validate(doc, man_schema)
        print(f"ok: manifest.yaml")
    except jsonschema.ValidationError as e:
        errors += 1
        print(f"FAIL: manifest.yaml — {e.message}")
else:
    print("FAIL: manifest.yaml missing"); errors += 1

# Validate each experiment
for path in sorted(glob.glob(os.path.join(root, "experiments", "*", "experiment.yaml"))):
    total += 1
    rel = os.path.relpath(path, root)
    with open(path) as f: doc = yaml.safe_load(f)
    try:
        jsonschema.validate(doc, exp_schema)
        print(f"ok: {rel}")
    except jsonschema.ValidationError as e:
        errors += 1
        print(f"FAIL: {rel} — {e.message}")

print(f"\n{total} experiments validated, {errors} errors")
sys.exit(1 if errors else 0)
PY
