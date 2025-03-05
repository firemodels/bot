#!/bin/bash

MAILTO=
if [ "$BUNDLE_EMAIL" != "" ]; then
  MAILTO="-m $BUNDLE_EMAIL"
fi

OWNER="-o firemodels"
if [ "$BUNDLE_OWNER" != "" ]; then
  OWNER="-o $BUNDLE_OWNER"
fi

#*** parse command line options

while getopts 'm:o:' OPTION
do
case $OPTION  in
  m)
   MAILTO="-m $OPTARG"
   ;;
  o)
   OWNER="-o $OPTARG"
   ;;
esac
done
shift $(($OPTIND-1))

# this script runs firebot to build fds manuals using revision and tags defined in config.sh
source config.sh
export DISABLEPUSH=1

CURDIR=`pwd`

echo ***setting up repos
cd ../../Scripts
./setup_repos.sh -A
./update_repos.sh -w
cd $CURDIR

cd ../../Firebot
./run_firebot.sh -G -C -f -c -J -q firebot $MAILTO -U -r test_bundles $OWNER -R release -z
