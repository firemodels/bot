#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GITROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
CFAST_REPO="$GITROOT/cfast"
SMV_REPO="$GITROOT/smv"
BUNDLE_DIR="${BUNDLE_DIR:-$HOME/.bundle/bundles}"
PYTHON_EXE="${PYTHON:-python3}"
UPLOAD=0
UPLOAD_OWNER=""
BUILD_CEDIT=1
INCLUDE_CEDIT=1
INCLUDE_SMOKEVIEW=1

usage()
{
  echo "Usage: build_cfast_linux_bundle.sh [options]"
  echo ""
  echo "Builds a CFAST Linux bundle using cfast/Build/bundle/build_linux_bundle.sh."
  echo ""
  echo "Options:"
  echo "  -E                 Do not rebuild CEditQt before bundling"
  echo "  -h                 Display this message"
  echo "  -u                 Upload to github.com/\$GH_OWNER/\$GH_REPO"
  echo "  -U                 Upload to github.com/firemodels/\$GH_REPO"
  echo "  --no-cedit         Do not include CEditQt in the bundle"
  echo "  --no-smokeview     Do not include Smokeview in the bundle"
  echo "  --output-dir path  Directory where the tarball is written"
  echo "  --python path      Python executable used to build CEditQt"
}

source_bundle_config()
{
  local config_file="$HOME/.bundle/bundle_config.sh"

  if [[ -f "$config_file" ]]; then
    # shellcheck source=/dev/null
    source "$config_file"
  fi
}

require_file()
{
  local file_path="$1"
  local description="$2"

  if [[ ! -f "$file_path" ]]; then
    echo "***error: $description not found: $file_path"
    exit 1
  fi
}

require_dir()
{
  local dir_path="$1"
  local description="$2"

  if [[ ! -d "$dir_path" ]]; then
    echo "***error: $description not found: $dir_path"
    exit 1
  fi
}

sanitize_name()
{
  printf "%s" "$1" | tr -cs "[:alnum:]_.-" "-"
}

cfast_bundle_name()
{
  local version

  version="$(git -C "$CFAST_REPO" describe --tags --dirty --always)"
  if [[ "$version" == CFAST* ]]; then
    printf "%s-linux" "$version"
  else
    printf "CFAST-%s-linux" "$version"
  fi
}

source_bundle_config

while [[ $# -gt 0 ]]; do
  case "$1" in
    -E)
      BUILD_CEDIT=0
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -u)
      UPLOAD=1
      shift
      ;;
    -U)
      UPLOAD=1
      UPLOAD_OWNER="firemodels"
      shift
      ;;
    --no-cedit)
      BUILD_CEDIT=0
      INCLUDE_CEDIT=0
      shift
      ;;
    --no-smokeview)
      INCLUDE_SMOKEVIEW=0
      shift
      ;;
    --output-dir)
      BUNDLE_DIR="$2"
      shift 2
      ;;
    --python)
      PYTHON_EXE="$2"
      shift 2
      ;;
    *)
      echo "***error: unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

if [[ "$UPLOAD_OWNER" == "" && "${GH_OWNER:-}" != "" ]]; then
  UPLOAD_OWNER="$GH_OWNER"
fi
if [[ "$UPLOAD_OWNER" == "" ]]; then
  UPLOAD_OWNER="$(whoami)"
fi

if [[ "$(uname)" != "Linux" ]]; then
  echo "***error: CFAST Linux bundles must be built on Linux."
  exit 1
fi

require_dir "$CFAST_REPO" "CFAST repository"
require_dir "$SMV_REPO" "Smokeview repository"
require_file "$CFAST_REPO/Build/CeditQt/build_linux_app.sh" "CEditQt Linux build script"
require_file "$CFAST_REPO/Build/bundle/build_linux_bundle.sh" "CFAST Linux bundle script"

mkdir -p "$BUNDLE_DIR"

echo "*** Building CFAST Linux bundle"
echo "*** CFAST repo: $CFAST_REPO"
echo "*** SMV repo:   $SMV_REPO"
echo "*** Output:     $BUNDLE_DIR"

if [[ "$BUILD_CEDIT" == "1" ]]; then
  echo "*** Building CEditQt"
  bash "$CFAST_REPO/Build/CeditQt/build_linux_app.sh" --python "$PYTHON_EXE"
fi

bundle_args=(
  --output-dir "$BUNDLE_DIR"
  --cfast-exe "$CFAST_REPO/Build/CFAST/intel_linux/cfast8_linux"
  --smokeview-exe "$SMV_REPO/Build/smokeview/intel_linux/smokeview_linux"
)

if [[ "$INCLUDE_CEDIT" == "0" ]]; then
  bundle_args+=(--no-cedit)
fi

if [[ "$INCLUDE_SMOKEVIEW" == "0" ]]; then
  bundle_args+=(--no-smokeview)
fi

bash "$CFAST_REPO/Build/bundle/build_linux_bundle.sh" "${bundle_args[@]}"

DIST_NAME="$(cfast_bundle_name)"
TARBALL_NAME="$(sanitize_name "$DIST_NAME").tar.gz"
TARBALL_PATH="$BUNDLE_DIR/$TARBALL_NAME"

require_file "$TARBALL_PATH" "CFAST Linux bundle"

echo "*** CFAST Linux bundle ready:"
echo "    $TARBALL_PATH"

if [[ "$UPLOAD" == "1" ]]; then
  "$SCRIPT_DIR/upload_cfast_linux_bundle.sh" "$BUNDLE_DIR" "$TARBALL_NAME" "$UPLOAD_OWNER"
fi
