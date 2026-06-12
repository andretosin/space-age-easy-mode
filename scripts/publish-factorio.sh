#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <zip-file>" >&2
  exit 1
fi

ZIP_PATH="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
INFO_JSON="${REPO_ROOT}/info.json"
INIT_UPLOAD_URL="https://mods.factorio.com/api/v2/mods/releases/init_upload"

if [[ ! -f "${ZIP_PATH}" ]]; then
  echo "Zip file not found: ${ZIP_PATH}" >&2
  exit 1
fi

if [[ -z "${FACTORIO_MOD_PORTAL_TOKEN:-}" ]]; then
  echo "FACTORIO_MOD_PORTAL_TOKEN is required" >&2
  exit 1
fi

read -r MOD_NAME VERSION < <(python - <<'PY' "${INFO_JSON}"
import json
import pathlib
import re
import sys

info_path = pathlib.Path(sys.argv[1])
with info_path.open("r", encoding="utf-8") as fh:
    data = json.load(fh)

name = data["name"]
version = data["version"]
if not re.fullmatch(r"(\d+)\.(\d+)\.(\d+)", version):
    raise SystemExit(f"Unsupported version format in info.json: {version}")

print(name, version)
PY
)

EXPECTED_ZIP="${MOD_NAME}_${VERSION}.zip"
if [[ "$(basename "${ZIP_PATH}")" != "${EXPECTED_ZIP}" ]]; then
  echo "Zip file name must match info.json version: expected ${EXPECTED_ZIP}" >&2
  exit 1
fi

echo "Requesting Factorio Mod Portal upload URL for ${MOD_NAME} ${VERSION}"
INIT_RESPONSE="$(curl --fail-with-body -sS \
  -X POST \
  -H "Authorization: Bearer ${FACTORIO_MOD_PORTAL_TOKEN}" \
  -F "mod=${MOD_NAME}" \
  "${INIT_UPLOAD_URL}")"

UPLOAD_URL="$(python - <<'PY' "${INIT_RESPONSE}"
import json
import sys

data = json.loads(sys.argv[1])
upload_url = data.get("upload_url")
if not upload_url:
    raise SystemExit(f"Upload URL missing from response: {data}")

if upload_url.startswith("/"):
    upload_url = "https://mods.factorio.com" + upload_url

print(upload_url)
PY
)"

echo "Uploading ${EXPECTED_ZIP} to Factorio Mod Portal"
curl --fail-with-body -sS \
  -X POST \
  -H "Authorization: Bearer ${FACTORIO_MOD_PORTAL_TOKEN}" \
  -F "file=@${ZIP_PATH}" \
  "${UPLOAD_URL}"

echo
echo "Published ${MOD_NAME} ${VERSION} to Factorio Mod Portal"
