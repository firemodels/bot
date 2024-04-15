u!/bin/bash
# this script runs firebot to build fds manuals using revision and tags defined in config.sh
source config.sh
export DISABLEPUSH=1

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
 ./run_firebot.sh -a -C -f -c -J -q firebot $MAILTO -U $GHREPO $GHOWNER -R release -z
