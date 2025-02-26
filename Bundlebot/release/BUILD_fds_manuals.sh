!/bin/bash
# this script runs firebot to build fds manuals using revision and tags defined in config.sh
source config.sh
export DISABLEPUSH=1

CURDIR=`pwd`
cd ../../Scripts
#echo ***updating repos
#./update_repos.sh -m
cd $CURDIR

MAILTO=
if [ "$BUNDLE_EMAIL" != "" ]; then
  MAILTO="-m $BUNDLE_EMAIL"
fi
cd ../../Firebot
./run_firebot.sh -C -f -c -J -q firebot $MAILTO -U -r test_bundles -o firemodels -R release -z
