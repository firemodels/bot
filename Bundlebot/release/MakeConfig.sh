#!/bin/bash
# This script builds the configuration scripts used to build the bundles
# usage:
# build both bash and dos config scripts
# ./MakeBuild_config.sh x.y.z

# build bash config script
# ./Make_config.sh x.y.z BASH

# build dos config script
# ./Make_config.sh x.y.z  DOS

# where x.y.z is the version being bundled

base_tag=$1
OS=$2

if [ "$OS" == "" ]; then
  BOTVERSION=`git describe --dirty --long`
  BOTREVISION=`git rev-parse --short HEAD`
  export BOTVERSION BOTREVISION
  ./MakeConfig.sh $base_tag BASH > config.sh
  cp config.sh history/config_${base_tag}.sh
  ./MakeConfig.sh $base_tag DOS  > config.bat
  cp config.bat history/config_${base_tag}.bat
  exit
fi
ERROR=1
if [ "$OS" == "DOS" ]; then
  ERROR=
fi
if [ "$OS" == "BASH" ]; then
  ERROR=
fi
if [ "$ERROR" != "" ]; then
  echo "***Error: found OS option $OS must be BASH, DOS or BOTH"
  exit
fi
if [ "$OS" == "BASH" ]; then
  HEAD="#!/bin/bash"
  COMMENT="#"
  EXPORT="export"
else
  HEAD="@echo off"
  COMMENT="::"
  EXPORT="set"
fi
export HEAD COMMENT EXPORT

repos="bot cad exp fds fig out smv"
CURDIR=`pwd`
gitroot=$CURDIR/../../..
cd $gitroot
gitroot=`pwd`
cd $CURDIR

cat << EOF
$HEAD
$COMMENT This scripts defines revisions and tags for a bundle.
$COMMENT It is run by other BUILD scripts to define the environment.
$COMMENT ----------------------------
$COMMENT repo environment variables

EOF

for repo in $repos
do
cd $gitroot/$repo
REPOVERSION=`git describe --dirty --long`
REVISION=`git rev-parse --short HEAD`
if [ "$repo" == "bot" ]; then
  REPOVERSION=$BOTVERSION
  REVISION=$BOTREVISION
fi
REPO=$(echo "$repo" | awk '{print toupper($0)}')
TAG=$REPO-${base_tag}
cat << EOF
$COMMENT $REPOVERSION
$EXPORT BUNDLE_${REPO}_REVISION=$REVISION
$EXPORT BUNDLE_${REPO}_TAG=$TAG

EOF

done
cat << EOF
$COMMENT ----------------------------
$COMMENT github environment variables

$EXPORT GH_REPO=test_bundles
$EXPORT GH_FDS_TAG=BUNDLE_TEST
$EXPORT GH_SMOKEVIEW_TAG=BUNDLE_TEST
EOF
