#!/bin/bash
# this script runs firebot to build fds manuals using revision and tags defined in config.sh
source config.sh

CURDIR=`pwd`
cd ../../Scripts
echo ***updating repos
./update_repos.sh -m
cd $CURDIR

MAILTO=
GHOWNER=
if [ "$BUNDLE_EMAIL" != "" ]; then
  MAILTO="-m $BUNDLE_EMAIL"
fi
if [ "$GH_OWNER" != "" ]; then
  GHOWNER="-o $GH_OWNER"
fi
if [ "$GH_REPO" != "" ]; then
  GHREPO="-r $GH_REPO"
fi
cd ../../Firebot
#./run_firebot.sh -C -c -J -q firebot $MAILTO -x $BUNDLE_FDS_REVISION -X $BUNDLE_FDS_TAG  -y $BUNDLE_SMV_REVISION -Y $BUNDLE_SMV_TAG -U $GHREPO $GHOWNER -R release
 ./run_firebot.sh -C -f -c -J -q firebot $MAILTO -U $GHREPO $GHOWNER -R release -z
