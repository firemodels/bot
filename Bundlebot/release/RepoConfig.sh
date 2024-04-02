#!/bin/bash
gitroot=$1
repo=$2
base_tag=$3

cd $gitroot/$repo
REPOVERSION=`git describe --dirty --long`
REVISION=`git rev-parse --short HEAD`
REPO=$(echo "$repo" | awk '{print toupper($0)}')
TAG=$REPO-${base_tag}
cat << EOF
$COMMENT $REPOVERSION
$EXPORT BUNDLE_${REPO}_REVISION=$REVISION
$EXPORT BUNDLE_${REPO}_TAG=$TAG

EOF
