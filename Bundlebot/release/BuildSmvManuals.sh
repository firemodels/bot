#!/bin/bash

MAILTO=
if [ "$BUNDLE_EMAIL" != "" ]; then
  MAILTO="-m $BUNDLE_EMAIL"
fi

OWNER="-o firemodels"
if [ "$BUNDLE_OWNER" != "" ]; then
  OWNER="-o $BUNDLE_OWNER"
fi

PROCEED=

#*** parse command line options

while getopts 'hm:o:y' OPTION
do
case $OPTION  in
  h)
   echo Usage:
   echo ./BuildSmvManuals.sh -o owner -m email_address
   exit
  ;;
  m)
   MAILTO="-m $OPTARG"
   ;;
  o)
   OWNER="-o $OPTARG"
   ;;
  y)
   PROCEED=1
   ;;
esac
done
shift $(($OPTIND-1))

# this script runs smokebot to build smokeview manuals using revision and tags defined in config.sh
source config.sh

echo Smokeview manuals will be built using:
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
if [ "$PROCEED" == "" ]; then
  echo "Press any key to continue or <CTRL> c to abort."
  echo "Type $0 -h for other options"
  read val
fi

CURDIR=`pwd`

cd ../../../
export REPOROOT=`pwd`
cd $CURDIR

echo ***clean files
cd $CURDIR/../../Smokebot
git clean -dxf >& /dev/null
cd $CURDIR/output
git clean -dxf >& /dev/null
cd $CURDIR/../nightly/output
git clean -dxf >& /dev/null

echo ***update bot, web and wiki repos
cd $CURDIR/../../Scripts
echo "update bot, web and wiki repos"
./update_repos.sh -b
./update_repos.sh -w

cd $CURDIR/../../Smokebot
echo ./run_smokebot.sh -f -q firebot $MAILTO $OWNER -r test_bundles -R release -U 
     ./run_smokebot.sh -f -q firebot $MAILTO $OWNER -r test_bundles -R release -U 
