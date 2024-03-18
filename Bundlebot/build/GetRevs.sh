#!/bin/bash
# This scripts defines revisions and tags for a bundle.
# It is run by the other BUILD scripts. 
# You do not need to run it.
base_tag=$1

repos="fds smv cad exp fig out"
CURDIR=`pwd`
gitroot=$CURDIR/../../..
cd $gitroot
gitroot=`pwd`
cd $CURDIR

for repo in $repos
do
if [ -e $gitroot/$repo ]; then
   cd $gitroot/$repo
   REVISION=`git rev-parse --short HEAD`
   REPO=$(echo "$repo" | awk '{print toupper($0)}')
   TAG=$REPO-${base_tag}
   echo export BUNDLE_${REPO}_REVISION=$REVISION
   echo export BUNDLE_${REPO}_TAG=$TAG
   echo
else
   echo "***error: repo $$gitroot/$repo does not exist"
fi
done
