#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
INFO_JSON="${REPO_ROOT}/info.json"

if [[ ! -f "${INFO_JSON}" ]]; then
  echo "info.json not found at ${INFO_JSON}" >&2
  exit 1
fi

read -r MOD_NAME NEW_VERSION < <(python - <<'PY' "${INFO_JSON}"
import json
import pathlib
import re
import sys

info_path = pathlib.Path(sys.argv[1])
with info_path.open("r", encoding="utf-8") as fh:
    data = json.load(fh)

name = data["name"]
version = data["version"]
match = re.fullmatch(r"(\d+)\.(\d+)\.(\d+)", version)
if not match:
    raise SystemExit(f"Unsupported version format in info.json: {version}")

major, minor, patch = map(int, match.groups())
new_version = f"{major}.{minor}.{patch + 1}"
data["version"] = new_version

with info_path.open("w", encoding="utf-8") as fh:
    json.dump(data, fh, ensure_ascii=False, indent=2)
    fh.write("\n")

print(name, new_version)
PY
)

PACKAGE_DIR_NAME="${MOD_NAME}_${NEW_VERSION}"
ZIP_NAME="${PACKAGE_DIR_NAME}.zip"
TMP_DIR="$(mktemp -d /tmp/${MOD_NAME}.XXXXXX)"
PACKAGE_DIR="${TMP_DIR}/${PACKAGE_DIR_NAME}"

cleanup() {
  rm -rf "${TMP_DIR}"
}
trap cleanup EXIT

mkdir -p "${PACKAGE_DIR}"

rsync -a \
  --exclude '.git/' \
  --exclude '*.zip' \
  --exclude "${PACKAGE_DIR_NAME}/" \
  "${REPO_ROOT}/" "${PACKAGE_DIR}/"

(
  cd "${TMP_DIR}"
  zip -r "${REPO_ROOT}/${ZIP_NAME}" "${PACKAGE_DIR_NAME}" >/dev/null
)

echo "Updated info.json version to ${NEW_VERSION}"
echo "Created ${ZIP_NAME}"
