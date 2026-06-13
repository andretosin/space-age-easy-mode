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
TEMP_FILES=()

cleanup() {
  for temp_file in "${TEMP_FILES[@]}"; do
    rm -f "${temp_file}"
  done
}
trap cleanup EXIT

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
INIT_RESPONSE_FILE="$(mktemp)"
TEMP_FILES+=("${INIT_RESPONSE_FILE}")
INIT_URL="$(python - <<'PY' "${INIT_UPLOAD_URL}" "${MOD_NAME}" "${FACTORIO_MOD_PORTAL_TOKEN}"
import sys
from urllib.parse import urlencode

base_url, mod_name, token = sys.argv[1:]
print(f"{base_url}?{urlencode({'mod': mod_name, 'token': token})}")
PY
)"
INIT_STATUS="$(curl -sS \
  -X POST \
  -o "${INIT_RESPONSE_FILE}" \
  -w "%{http_code}" \
  "${INIT_URL}")"

if [[ "${INIT_STATUS}" -lt 200 || "${INIT_STATUS}" -ge 300 ]]; then
  echo "Factorio Mod Portal init_upload failed with HTTP ${INIT_STATUS}" >&2
  cat "${INIT_RESPONSE_FILE}" >&2
  echo >&2
  exit 1
fi

INIT_RESPONSE="$(cat "${INIT_RESPONSE_FILE}")"

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
UPLOAD_RESPONSE_FILE="$(mktemp)"
TEMP_FILES+=("${UPLOAD_RESPONSE_FILE}")
UPLOAD_STATUS="$(curl -sS \
  -X POST \
  -o "${UPLOAD_RESPONSE_FILE}" \
  -w "%{http_code}" \
  -F "file=@${ZIP_PATH}" \
  "${UPLOAD_URL}")"

if [[ "${UPLOAD_STATUS}" -lt 200 || "${UPLOAD_STATUS}" -ge 300 ]]; then
  echo "Factorio Mod Portal upload failed with HTTP ${UPLOAD_STATUS}" >&2
  cat "${UPLOAD_RESPONSE_FILE}" >&2
  echo >&2
  exit 1
fi

cat "${UPLOAD_RESPONSE_FILE}"

echo
echo "Published ${MOD_NAME} ${VERSION} to Factorio Mod Portal"
