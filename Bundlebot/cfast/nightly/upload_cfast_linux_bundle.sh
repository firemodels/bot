#!/usr/bin/env bash
set -euo pipefail

FROM_DIR="${1:-}"
FROM_FILE="${2:-}"
UPLOAD_OWNER="${3:-${GH_OWNER:-}}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GITROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
CFAST_REPO="$GITROOT/cfast"
GH_REPO="${GH_REPO:-test_bundles}"
GH_CFAST_TAG="${GH_CFAST_TAG:-CFAST_TEST}"

usage()
{
  echo "Usage: upload_cfast_linux_bundle.sh from_dir from_file [owner]"
}

source_bundle_config()
{
  local config_file="$HOME/.bundle/bundle_config.sh"

  if [[ -f "$config_file" ]]; then
    # shellcheck source=/dev/null
    source "$config_file"
  fi
}

if [[ "$FROM_DIR" == "-h" || "$FROM_DIR" == "--help" ]]; then
  usage
  exit 0
fi

if [[ "$FROM_DIR" == "" || "$FROM_FILE" == "" ]]; then
  usage
  exit 1
fi

source_bundle_config

if [[ "$UPLOAD_OWNER" == "" && "${GH_OWNER:-}" != "" ]]; then
  UPLOAD_OWNER="$GH_OWNER"
fi
if [[ "$UPLOAD_OWNER" == "" ]]; then
  UPLOAD_OWNER="$(whoami)"
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "***error: gh command not found"
  exit 1
fi

FULL_FILE="$FROM_DIR/$FROM_FILE"
if [[ ! -f "$FULL_FILE" ]]; then
  echo "***error: $FROM_FILE does not exist in $FROM_DIR"
  exit 1
fi

REPO_SPEC="github.com/$UPLOAD_OWNER/$GH_REPO"

echo "*** Uploading $FROM_FILE to $REPO_SPEC release $GH_CFAST_TAG"

if gh release view "$GH_CFAST_TAG" -R "$REPO_SPEC" --json assets >/dev/null 2>&1; then
  while read -r asset_name; do
    if [[ "$asset_name" == CFAST*linux*.tar.gz ]]; then
      echo "*** Removing previous CFAST Linux bundle: $asset_name"
      gh release delete-asset "$GH_CFAST_TAG" "$asset_name" -R "$REPO_SPEC" -y
    fi
  done < <(gh release view "$GH_CFAST_TAG" -R "$REPO_SPEC" --json assets -q ".assets[].name")
fi

gh release upload "$GH_CFAST_TAG" "$FULL_FILE" --clobber -R "$REPO_SPEC"

if [[ -d "$CFAST_REPO/.git" ]]; then
  CFAST_SHORT_HASH="$(git -C "$CFAST_REPO" rev-parse --short HEAD)"
  BUNDLEBOT_NIGHTLY="$GITROOT/bot/Bundlebot/nightly"
  if [[ -x "$BUNDLEBOT_NIGHTLY/setreleasetitle.sh" && "$GH_REPO" == "test_bundles" ]]; then
    (
      cd "$BUNDLEBOT_NIGHTLY"
      ./setreleasetitle.sh cfast "$CFAST_SHORT_HASH" "$UPLOAD_OWNER"
    )
  fi
fi
