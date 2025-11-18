#!/bin/bash

function usage {
echo "Clone fds or smv repo"
echo ""
echo "Options:"
echo "-b - base branch - default: $base_branch"
echo "-F - clone fds repo"
echo "-h - display this message"
echo "-N - clone for a nightly bundle"
echo "-r rev - repo revision or hash"
echo "-S - clone smv repo"
echo "-t tag - tag repo with tag"
exit 0
}

releaseornightly="release"
base_branch="master"
repo_revision=
repo_tag=
fdsorsmv="fds"

while getopts 'b:FhNr:St:' OPTION
do
case $OPTION  in
  b)
   base_branch="$OPTARG"
   ;;
  F)
   fdsorsmv="fds"
   ;;
  h)
   usage;
   ;;
  N)
   releaseornightly="nightly"
   ;;
  r)
   repo_revision="$OPTARG"
   ;;
  S)
   fdsorsmv="smv"
   ;;
  t)
   repo_tag="$OPTARG"
   ;;
esac
done
shift $(($OPTIND-1))

abort=
if [ "$repo_revision" == "" ]; then
  abort=1
  echo "***error: -h hash not specified"
fi
if [ "$abort" != "" ]; then
  exit
fi

CURDIR=`pwd`
cd ../../..
REPOROOT=`pwd`

cd $REPOROOT/bot/Scripts
if [ "$fdsorsmv" == "fds" ]; then
  ./setup_repos.sh -V
fi
if [ "$fdsorsmv" == "smv" ]; then
  ./setup_repos.sh -U
fi

cd $REPOROOT/$fdsorsmv
git checkout $base_branch
git checkout -b $releaseornightly $repo_revision
if [ "$repo_tag" != "" ]; then
  git tag -a $repo_tag -m "tag for $repo_tag"
fi
git describe --abbrev=7 --dirty --long
