#!/bin/bash
# This scripts obtains revisions and tags for a bundle.

base_tag=$1
OS=$2

if [ "$OS" != "DOS" ]; then
  OS="BASH"
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
