#!/bin/bash
# Build configured FDS/Smokeview commits locally, using manuals from GitHub.
set -euo pipefail

SCRIPTDIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPOROOT=$(cd "$SCRIPTDIR/../../.." && pwd)
CONFIG=$SCRIPTDIR/config.sh
MANUALS_REPO=firemodels/test_bundles
FDS_MANUALS_TAG=FDS_TEST
SMV_MANUALS_TAG=SMOKEVIEW_TEST
OUTPUT=$HOME/.bundle/bundles
CHECK_ONLY=0
PACKAGE_ONLY=0
ALLOW_MANUAL_REVISION_MISMATCH=0

usage() {
  cat <<'EOF'
Usage: bash BuildMacRelease.sh [options]
Build the commits in config.sh with GNU Fortran/Open MPI and create a macOS DMG.
Manuals must already be uploaded by Firebot and Smokebot at those revisions.
Builds clean and reset the sibling fds/smv checkouts to the configured commits.
Sibling hypre/sundials checkouts are reused; missing ones are cloned.

  --config FILE             Bundle configuration (default: adjacent config.sh)
  --manuals-repo OWNER/REPO Manual release repository (firemodels/test_bundles)
  --fds-manuals-tag TAG     FDS manual release (FDS_TEST)
  --smv-manuals-tag TAG     Smokeview manual release (SMOKEVIEW_TEST)
  --output-dir DIR         Output directory ($HOME/.bundle/bundles)
  --check                  Check tools, commits and downloaded manuals only
  --package-only           Repackage the staged bundle from the last build
  --allow-manual-revision-mismatch  Use other manual revisions for a packaging test
  -h, --help               Show this help

Run on the desired Mac architecture. Nothing is uploaded automatically.
EOF
}
fail() { echo "ERROR: $*" >&2; exit 1; }
while (( $# )); do
  case $1 in
    --config|--manuals-repo|--fds-manuals-tag|--smv-manuals-tag|--output-dir)
      (( $# >= 2 )) || fail "Missing value for $1"
      case $1 in
        --config) CONFIG=$2 ;;
        --manuals-repo) MANUALS_REPO=$2 ;;
        --fds-manuals-tag) FDS_MANUALS_TAG=$2 ;;
        --smv-manuals-tag) SMV_MANUALS_TAG=$2 ;;
        --output-dir) OUTPUT=$2 ;;
      esac
      shift 2 ;;
    --check) CHECK_ONLY=1; shift ;;
    --package-only) PACKAGE_ONLY=1; shift ;;
    --allow-manual-revision-mismatch) ALLOW_MANUAL_REVISION_MISMATCH=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) fail "Unknown option: $1" ;;
  esac
done

package_dmg() {
  echo "Creating drag-to-Applications DMG"
  python3 "$SCRIPTDIR/make_macos_dmg.py" "$DIST" "$WORK/$NAME.dmg" \
    --volume-name "${BUNDLE_FDS_TAG}_${BUNDLE_SMV_TAG}"
  hdiutil verify "$WORK/$NAME.dmg"
  cp "$WORK/$NAME.dmg" "$OUTPUT/$NAME.dmg"
  echo "Created: $OUTPUT/$NAME.dmg"
  echo "No upload performed. Build files retained in $WORK"
}

[[ $(uname -s) == Darwin ]] || fail "Run this script on macOS."
python3 -c 'import dmgbuild; from PIL import Image' || fail "Python needs dmgbuild and Pillow."
if (( PACKAGE_ONLY )); then
  (( CHECK_ONLY == 0 )) || fail "Use --package-only or --check, not both."
  OUTPUT=$(cd "$OUTPUT" && pwd)
  WORK=$OUTPUT/.macos-build
  LOCK=$OUTPUT/.macos-build.lock
  mkdir "$LOCK" 2>/dev/null || fail "Another macOS bundle run holds $LOCK"
  trap 'rmdir "$LOCK"' EXIT
  [[ -f $WORK/config.sh ]] || fail "No previous bundle configuration in $WORK"
  source "$WORK/config.sh"
  NAME=${BUNDLE_FDS_TAG}_${BUNDLE_SMV_TAG}_macos_$(uname -m)
  if [[ -f $WORK/manuals/manuals_test.txt ]]; then NAME=${NAME}_manuals_test; fi
  DIST=$WORK/$NAME
  [[ -d $DIST ]] || fail "No staged bundle in $DIST; run a full build first."
  package_dmg
  exit 0
fi
for tool in git gh python3 mpifort mpicc ompi_info pkg-config gfortran cmake make file otool install_name_tool codesign hdiutil; do
  command -v "$tool" >/dev/null || fail "Required tool not found: $tool"
done
source "$CONFIG"
CONFIG_SNAPSHOT=$(cat "$CONFIG")
FDS_HASH=$(git -C "$REPOROOT/fds" rev-parse --verify "${BUNDLE_FDS_HASH}^{commit}")
SMV_HASH=$(git -C "$REPOROOT/smv" rev-parse --verify "${BUNDLE_SMV_HASH}^{commit}")
[[ $BUNDLE_FDS_TAG =~ ^FDS-[0-9]+\.[0-9]+\.[0-9]+$ ]] || fail "Invalid FDS release tag"
[[ $BUNDLE_SMV_TAG =~ ^SMV-[0-9]+\.[0-9]+\.[0-9]+$ ]] || fail "Invalid Smokeview release tag"
MPI_PREFIX=$(ompi_info --path prefix --parsable | sed -n 's/^path:prefix://p')
[[ -x $MPI_PREFIX/bin/mpirun ]] || fail "Open MPI runtime not found."
PMIX_PREFIX=$(pkg-config --variable=prefix pmix)
[[ -n $PMIX_PREFIX ]] || fail "PMIx runtime prefix not found by pkg-config."

mkdir -p "$OUTPUT"
OUTPUT=$(cd "$OUTPUT" && pwd)
WORK=$OUTPUT/.macos-build
if (( CHECK_ONLY == 0 )) && [[ $WORK == *[[:space:]]* || $REPOROOT == *[[:space:]]* ]]; then
  fail "The existing compiler helpers require repository and output paths without spaces."
fi
LOCK=$OUTPUT/.macos-build.lock
mkdir "$LOCK" 2>/dev/null || fail "Another macOS bundle run holds $LOCK"
trap 'rmdir "$LOCK"' EXIT
[[ ! -L $WORK ]] || fail "Staging directory must not be a symlink: $WORK"
rm -rf "$WORK"
mkdir "$WORK"
echo "Build files and logs: $WORK"
trap 'echo "Build stopped; files retained in $WORK" >&2' ERR
PUBS=$WORK/manuals
mkdir -p "$PUBS"
printf '%s\n' "$CONFIG_SNAPSHOT" > "$WORK/config.sh"

download_manuals() {
  local kind=$1 tag=$2 expected=$3 info assets hash revision
  assets=$(gh release view "$tag" -R "$MANUALS_REPO" --json assets --jq '.assets[].name')
  info=${kind}_INFO.txt
  # Older Firebot versions upload a literal dollar sign in this asset name.
  if [[ $kind == FDS ]] && printf '%s\n' "$assets" | grep -Fxq 'FDS_INFO$.txt'; then
    info='FDS_INFO$.txt'
  fi
  gh release download "$tag" -R "$MANUALS_REPO" -p "$info" -D "$PUBS"
  hash=$(awk -v key="${kind}_HASH" '$1 == key {print $2; exit}' "$PUBS/$info")
  revision=$(awk -v key="${kind}_REVISION" '$1 == key {print $2; exit}' "$PUBS/$info")
  local configured_tag=$BUNDLE_FDS_TAG
  [[ $kind == FDS ]] || configured_tag=$BUNDLE_SMV_TAG
  if (( ALLOW_MANUAL_REVISION_MISMATCH )); then
    echo "Packaging test: $tag manuals report $revision ($hash); building $configured_tag ($expected)."
  else
    [[ $hash =~ ^[0-9a-f]{7,40}$ && $expected == "$hash"* ]] ||
      fail "$tag manuals have $kind hash '$hash'; configuration requires $expected."
    [[ $revision == "$configured_tag"-0-g* && $revision != *dirty* ]] ||
      fail "$tag manuals report '$revision'; expected $configured_tag at the configured commit."
  fi
  shift 3
  local pdf
  for pdf in "$@"; do
    gh release download "$tag" -R "$MANUALS_REPO" -p "$pdf.pdf" -D "$PUBS"
    [[ $(head -c 5 "$PUBS/$pdf.pdf") == '%PDF-' ]] || fail "Invalid PDF: $pdf.pdf"
  done
}

echo "Checking release manuals before building executables"
download_manuals FDS "$FDS_MANUALS_TAG" "$FDS_HASH" \
  FDS_Config_Management_Plan FDS_Technical_Reference_Guide FDS_User_Guide \
  FDS_Validation_Guide FDS_Verification_Guide
download_manuals SMV "$SMV_MANUALS_TAG" "$SMV_HASH" \
  SMV_Technical_Reference_Guide SMV_User_Guide SMV_Verification_Guide
if (( ALLOW_MANUAL_REVISION_MISMATCH )); then
  echo "Packaging test: manual revisions were not required to match the executables." |
    tee "$PUBS/manuals_test.txt"
else
  echo "Manuals match $BUNDLE_FDS_TAG/$FDS_HASH and $BUNDLE_SMV_TAG/$SMV_HASH"
fi
(( CHECK_ONLY == 0 )) || exit 0

# The repositories alongside bot are the bundle work area. Only the source
# checkouts are reset; keep bot's running scripts and release configuration.
ROOT=$REPOROOT
for repo in fds smv; do
  hash=$FDS_HASH; tag=$BUNDLE_FDS_TAG
  if [[ $repo == smv ]]; then hash=$SMV_HASH; tag=$BUNDLE_SMV_TAG; fi
  git -C "$ROOT/$repo" clean -dxf
  git -C "$ROOT/$repo" checkout --quiet -f -B release "$hash"
  git -C "$ROOT/$repo" -c user.name=Bundlebot -c user.email=bundlebot@localhost \
    tag -f -a "$tag" "$hash" -m "$tag local bundle build"
done
for spec in hypre:hypre-space sundials:LLNL; do
  repo=${spec%:*}; owner=${spec#*:}
  if [[ -d $ROOT/$repo/.git ]]; then
    git -C "$ROOT/$repo" fetch origin --tags
  else
    git clone --quiet "https://github.com/$owner/$repo.git" "$ROOT/$repo"
  fi
done
export FIREMODELS=$ROOT
export BUNDLE_FDSCOMPILER=gnu BUNDLE_SMVCOMPILER=gnu BUNDLE_MPITYPE=OPENMPI

run_build() {
  local dir=$1 script=$2 log=$3
  shift 3
  echo "Building $log (log: $WORK/$log.log)"
  (cd "$dir" && bash "$script" "$@") 2>&1 | tee "$WORK/$log.log" || {
    fail "$log build failed"
  }
}
APPS=$ROOT/bot/Bundlebot/nightly/apps
mkdir -p "$APPS" "$ROOT/bot/Bundlebot/nightly/output"
for prog in fds fds2ascii test_mpi smokeview smokediff pnginfo fds2fed smokezip wind2fds; do
  rm -f "$APPS/$prog"
done
run_build "$ROOT/fds/Build/ompi_gnu_osx" ./make_fds.sh fds --clean-all
cp "$ROOT/fds/Build/ompi_gnu_osx/fds_ompi_gnu_osx" "$APPS/fds"
for spec in fds2ascii:gnu_osx test_mpi:ompi_gnu_osx; do
  prog=${spec%:*}; target=${spec#*:}
  run_build "$ROOT/fds/Utilities/$prog/$target" "./make_$prog.sh" "$prog"
  exe=${prog}_$target
  [[ $prog != test_mpi ]] || exe=test_mpi
  cp "$ROOT/fds/Utilities/$prog/$target/$exe" "$APPS/$prog"
done
run_build "$ROOT/bot/Bundlebot/nightly" ./make_smvapps.sh smokeview

NAME=${BUNDLE_FDS_TAG}_${BUNDLE_SMV_TAG}_macos_$(uname -m)
if (( ALLOW_MANUAL_REVISION_MISMATCH )); then NAME=${NAME}_manuals_test; fi
DIST=$WORK/$NAME
mkdir -p "$DIST/bin/openmpi/bin" "$DIST/smvbin" "$DIST/Documentation" "$DIST/Examples"
for prog in fds fds2ascii test_mpi; do
  [[ -x $APPS/$prog ]] || fail "Missing executable: $prog"
  cp "$APPS/$prog" "$DIST/bin/"
done
for prog in smokeview smokediff pnginfo fds2fed smokezip wind2fds; do
  [[ -x $APPS/$prog ]] || fail "Missing executable: $prog (see Smokeview logs)"
  cp "$APPS/$prog" "$DIST/smvbin/"
done
for item in objects.svo smokeview.ini volrender.ssf .smokeview_bin colorbars textures; do
  cp -R "$ROOT/smv/Build/for_bundle/$item" "$DIST/smvbin/"
done
cp "$ROOT/smv/Utilities/Scripts/jp2conv.sh" "$DIST/smvbin/"
cp "$PUBS/"* "$DIST/Documentation/"
cp "$WORK/config.sh" "$DIST/Documentation/bundle_config.sh"
for repo in fds smv; do
  mkdir -p "$DIST/Examples/$repo"
  (cd "$ROOT/$repo/Verification" && git ls-files -z -- '*.fds' '*.ini' '*.ssf' '*.csv' '*.bingeom' '*.obj' '*.stl' |
    tar --null -T - -cf -) | tar -xf - -C "$DIST/Examples/$repo"
done

# Include MPI daemons as well as mpirun; collect their transitive libraries.
for prog in mpirun mpiexec prterun prte prted orted; do
  if [[ -x $MPI_PREFIX/bin/$prog ]]; then
    cp -L "$MPI_PREFIX/bin/$prog" "$DIST/bin/openmpi/bin/"
  fi
done
for prefix in "$MPI_PREFIX" "$PMIX_PREFIX"; do
  for item in share/openmpi share/prte share/pmix lib/openmpi lib/pmix lib/prte; do
    if [[ -d $prefix/$item ]]; then
      mkdir -p "$DIST/bin/openmpi/$(dirname "$item")"
      cp -RL "$prefix/$item" "$DIST/bin/openmpi/$(dirname "$item")/"
    fi
  done
done
python3 "$SCRIPTDIR/macos_runtime.py" "$DIST" "$MPI_PREFIX"
for prog in mpirun mpiexec; do
  [[ -x $DIST/bin/openmpi/bin/$prog ]] || continue
  mv "$DIST/bin/openmpi/bin/$prog" "$DIST/bin/openmpi/bin/$prog.bin"
  cat > "$DIST/bin/openmpi/bin/$prog" <<'EOF'
#!/bin/bash
MPI_ROOT=$(cd "$(dirname "$0")/.." && pwd)
export OPAL_PREFIX=$MPI_ROOT PRTE_PREFIX=$MPI_ROOT PMIX_PREFIX=$MPI_ROOT
exec "$MPI_ROOT/bin/$(basename "$0").bin" "$@"
EOF
  chmod +x "$DIST/bin/openmpi/bin/$prog"
done

package_dmg
