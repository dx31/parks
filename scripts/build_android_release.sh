#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

if [[ -z "${API_PROD_URL:-}" ]]; then
  echo "Falta API_PROD_URL. En GitHub: Settings → Secrets and variables → Actions."
  exit 1
fi

python3 - <<'PY'
import json
import os
from pathlib import Path

Path("api_env.json").write_text(
    json.dumps(
        {"API_ENV": "prod", "API_PROD_URL": os.environ["API_PROD_URL"]},
        indent=2,
    ),
    encoding="utf-8",
)
PY

for app in operator client; do
  echo "Building $app against the production API..."
  (
    cd "$root/apps/$app"
    flutter pub get
    flutter build apk --release --dart-define-from-file="$root/api_env.json"
  )
done
