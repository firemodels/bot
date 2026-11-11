#!/bin/bash

if [ "$(uname -s)" = "Darwin" ] && [ "$(uname -m)" = "x86_64" ]; then
  echo "Error: bundles cannot be built on Intel Macs, only ARM Macs are supported." >&2
  exit 1
fi

OWNER=`whoami`

stop_release=0
while getopts "kno:" option; do
  case "$option" in
    k) stop_release=1 ;;
    n) new_mac_release=1 ;;
    o) OWNER=$OPTARG ;;
  esac
done
shift "$((OPTIND - 1))"

PIDFILE="$PWD/BuildRelease.pid"

if [ "$stop_release" = 1 ]; then
  if [ -f "$PIDFILE" ]; then
    PID=$(head -n 1 "$PIDFILE")
    if [[ ! "$PID" =~ ^[1-9][0-9]+$ ]]; then
      echo "Error: invalid PID in $PIDFILE" >&2
      exit 1
    fi
    echo "*** killing process group $PID"
    kill -KILL -- "-$PID" || exit 1
    rm -f "$PIDFILE"
  else
    echo "*** warning: BuildRelease.sh is not running"
  fi
  exit
fi

if [ "$new_mac_release" != "" ]; then
  if [ "$(uname -s)" = "Darwin" ]; then
    exec bash "$(dirname "$0")/BuildMacRelease.sh" "$@"
  fi
fi

PIDFILE=`pwd`/BuildRelease.pid

echo $$ > "$PIDFILE"
# build a release bundle using revision and tags defined in config.sh .
source config.sh
export DISABLEPUSH=1

# for testing build bundle with a specified hash and tag
#export BUNDLE_FDS_HASH=889da6ae0
#export BUNDLE_FDS_TAG=FDS-6.9.1test
#export BUNDLE_SMV_HASH=xxxxx
#export BUNDLE_SMV_TAG=SMV-6.9.1test

CURDIR=`pwd`

echo ***cleaning bot repo
cd $CURDIR/../../Firebot
git clean -dxf  >& /dev/null
cd $CURDIR/output
git clean -dxf  >& /dev/null
cd $CURDIR/../nightly
git clean -dxf  >& /dev/null

cd $CURDIR/../nightly
./BuildNightly.sh -c -f -R -o "$OWNER" -r test_bundles -u

cd $CURDIR
TITLE="Bundle Test - $BUNDLE_FDS_TAG/$BUNDLE_FDS_HASH - $BUNDLE_SMV_TAG/$BUNDLE_SMV_HASH"
gh release edit FDS_TEST  -t "$TITLE" -R "github.com/$OWNER/test_bundles"
rm -f "$PIDFILE"
