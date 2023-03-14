#!/bin/bash
repo=$1
hash=$2

ERROR=1
if [ "$repo" == "fds" ]; then
  PREFIX="FDS test"
  tag=FDS_TEST
  ERROR=
fi
if [ "$repo" == "cfast" ]; then
  PREFIX="CFAST test"
  tag=CFAST_TEST
  ERROR=
fi
if [ "$repo" == "smv" ]; then
  PREFIX="Smokeview test"
  tag=SMOKEVIEW_TEST
  ERROR=
fi
if [ "$ERROR" != "" ]; then
  exit
fi

cd ../../$repo
INFO="`git show -s --format=%cd --date=format:'%Y-%b-%d %H:%M:%S' $hash`"
TITLE="$PREFIX"
if [ "$INFO" != "" ]; then
  TITLE="$TITLE ($hash committed: $INFO)"
fi
gh release edit $tag -t "$TITLE" -R github.com/$GH_OWNER/$GH_REPO
