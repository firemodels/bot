#!/bin/bash
repo=$1
hash=$2
GHOWNER=$3

if [ "$GHOWNER" == "" ]; then
  echo "***error: owner for gh command not defined"
  exit
fi

ERROR=1
if [ "$repo" == "fds" ]; then
  tag=FDS_TEST
  ERROR=
fi
if [ "$repo" == "cfast" ]; then
  tag=CFAST_TEST
  ERROR=
fi
if [ "$repo" == "smv" ]; then
  tag=SMOKEVIEW_TEST
  ERROR=
fi
if [ "$ERROR" != "" ]; then
  exit
fi

cd ../../../$repo
TITLE=`git describe --abbrev=7 --long --dirty`
INFO="`git show -s --format=%cd --date=format:'%Y-%b-%d %H:%M' $hash`"
if [ "$INFO" != "" ]; then
  TITLE="$TITLE $INFO"
fi
gh release edit $tag -t "$TITLE" -R github.com/$GHOWNER/test_bundles
