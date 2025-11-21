#!/bin/bash
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
CURDIR=`pwd`
cd $SCRIPTDIR/../../..
REPOROOT=`pwd`
cd $SCRIPTDIR

# ------------------- usage -----------------------------

function usage {
echo "Clone all repos using hash and tags in config.sh"
echo ""
echo "Options:"
echo "-h - display this message"
exit 0
}

# ------------------- TAG_REPO -----------------------------

TAG_REPO(){
  repo=$1
  repohash=$2
  repotag=$3

  cd $REPOROOT/$repo
  git checkout -b release $repohash >& /dev/null
  git tag -a $repotag -m "repo: $repo tag: $repotag"
  git describe --abbrev=7 --dirty --long
}

releaseornightly="release"
base_branch="master"
repo_revision=
repo_tag=
fdsorsmv="fds"

while getopts 'h' OPTION
do
case $OPTION  in
  h)
   usage;
   ;;
esac
done
shift $(($OPTIND-1))


source $REPOROOT/bot/Bundlebot/release/config.sh

cd $REPOROOT/bot/Scripts

./setup_repos.sh -F -D


TAG_REPO cad  $BUNDLE_CAD_HASH $BUNDLE_CAD_TAG
TAG_REPO exp  $BUNDLE_EXP_HASH $BUNDLE_EXP_TAG
TAG_REPO fds  $BUNDLE_FDS_HASH $BUNDLE_FDS_TAG
TAG_REPO fig  $BUNDLE_FIG_HASH $BUNDLE_FIG_TAG
TAG_REPO out  $BUNDLE_OUT_HASH $BUNDLE_OUT_TAG
TAG_REPO smv  $BUNDLE_SMV_HASH $BUNDLE_SMV_TAG
