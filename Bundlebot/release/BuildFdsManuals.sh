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
echo "     OWNER: $OWNER"
if [ "$MAILTO" == "" ]; then
echo "     email: not specified (use -m username@mailserver.xyz)"
else
echo "    MAILTO: $MAILTO"
fi
echo "   command: $0 $OWNER $MAILTO"
echo "  FDS repo: $BUNDLE_FDS_TAG $BUNDLE_FDS_HASH"
echo "  SMV repo: $BUNDLE_SMV_TAG $BUNDLE_SMV_HASH"
echo ""
echo "Press any key to continue or <CTRL> c to abort."
echo "Type $0 -h for other options"
read val

CURDIR=`pwd`

cd ../../..
REPOROOT=`pwd`
cd $CURDIR

echo ***clean files
cd $CURDIR/../../Firebot
git clean -dxf >& /dev/null
cd $CURDIR/output
git clean -dxf >& /dev/null
cd $CURDIR/../nightly
git clean -dxf >& /dev/null

echo ***clone repos
cd $REPOROOT/bot/Scripts
./setup_repos.sh -D -A
./update_repos.sh -w
cd $CURDIR

# setup branches and tags
cd $REPOROOT/fds
git checkout -b release $BUNDLE_FDS_REVISION
git tag -a $BUNDLE_FDS_TAG -m "tag: $BUNDLE_FDS_TAG"

cd $REPOROOT/smv
git checkout -b release $BUNDLE_SMV_REVISION
git tag -a $BUNDLE_SMV_TAG -m "tag: $BUNDLE_SMV_TAG"

cd $REPOROOT/cad
git checkout -b release $BUNDLE_CAD_REVISION
git tag -a $BUNDLE_CAD_TAG -m "tag: $BUNDLE_CAD_TAG"

cd $REPOROOT/exp
git checkout -b release $BUNDLE_EXP_REVISION
git tag -a $BUNDLE_EXP_TAG -m "tag: $BUNDLE_EXP_TAG"

cd $REPOROOT/fig
git checkout -b release $BUNDLE_FIG_REVISION
git tag -a $BUNDLE_FIG_TAG -m "tag: $BUNDLE_FIG_TAG"

cd $REPOROOT/out
git checkout -b release $BUNDLE_OUT_REVISION
git tag -a $BUNDLE_OUT_TAG -m "tag: $BUNDLE_OUT_TAG"

# build manuals
cd $REPOROOT/bot/Firebot
./run_firebot.sh -b -C -f -c -J -q firebot $MAILTO -U -r test_bundles $OWNER
