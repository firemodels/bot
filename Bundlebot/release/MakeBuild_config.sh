#!/bin/bash
# This scripts obtains revisions and tags for a bundle.

base_tag=$1
OS=$2

if [ "$OS" == "BOTH" ]; then
  ./MakeBuild_config.sh $base_tag BASH > BUILD_config.sh
  cp BUILD_config.sh history/BUILD_config_${base_tag}.sh
  ./MakeBuild_config.sh $base_tag DOS  > BUILD_config.bat
  cp BUILD_config.bat history/BUILD_config_${base_tag}.bat
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

repos="cad exp fds fig out smv"
CURDIR=`pwd`
gitroot=$CURDIR/../../..
cd $gitroot
gitroot=`pwd`
cd $CURDIR

cat << EOF
$HEAD
$COMMENT This scripts defines revisions and tags for a bundle.
$COMMENT It is run by the other BUILD scripts.
$COMMENT You do not need to run it.

EOF

for repo in $repos
do
./RepoConfig.sh $gitroot $repo $base_tag 
done
cat << EOF
$COMMENT the lines below should not need to be changed

$EXPORT GH_REPO=test_bundles
$EXPORT GH_FDS_TAG=BUNDLE_TEST
$EXPORT GH_SMOKEVIEW_TAG=BUNDLE_TEST
EOF
