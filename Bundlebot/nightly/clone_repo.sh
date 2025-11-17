#!/bin/bash
releaseornightly="nightly"
base_branch="master"
repo_hash=
repo_tag=
fdsorsmv="fds"

while getopts 'b:Fh:NRSt:' OPTION
do
case $OPTION  in
  b)
   base_branch="$OPTARG"
   ;;
  F)
   fdsorsmv="fds"
   ;;
  h)
   repo_hash="$OPTARG"
   ;;
  N)
   releaseornightly="nightly"
   ;;
  R)
   releaseornightly="release"
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
if [ "$repo_hash" == "" ]; then
  abort=1
  echo ***error: -h hash not specified"
fi
if [ "$repo_tag" == "" ]; then
  abort=1
  echo ***error: -t tag not specified"
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
git checkout -b $releaseornightly $repo_hash
git tag -a $repo_tag -m "tag for $repo_tag"
git describe --abbrev=7 --dirty --long
