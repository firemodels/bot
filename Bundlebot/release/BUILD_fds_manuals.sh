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

while getopts 'hm:o:' OPTION
do
case $OPTION  in
  h)
   echo Usage:
   echo ./BUILD_fds_manuals.sh -o owner -m email_address
   exit
   ;;
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

echo FDS manuals will be built using:
echo "  OWNER=$OWNER"
if [ "$MAILTO" == "" ]; then
  echo "  email address (-m) not specified"
else
  echo "  MAILTO=$MAILTO"
fi
echo "  FDS repo: $BUNDLE_FDS_TAG $BUNDLE_FDS_REVISION"
echo "  SMV repo info: $BUNDLE_SMV_TAG $BUNDLE_SMV_REVISION"

CURDIR=`pwd`

echo ***clean files
cd ../../Firebot
git clean -dxf >& /dev/null
cd $CURDIR/output
git clean -dxf >& /dev/null
cd $CURDIR/../nightly
git clean -dxf >& /dev/null

cd $CURDIR

echo ***setting up repos
cd ../../Scripts
./setup_repos.sh -A
./update_repos.sh -w
cd $CURDIR

cd ../../Firebot
./run_firebot.sh -G -C -f -c -J -q firebot $MAILTO -U -r test_bundles $OWNER -R release -z
