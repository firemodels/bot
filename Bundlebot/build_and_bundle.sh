#!/bin/bash

#---------------------------------------------
#                   usage
#---------------------------------------------

function usage {
echo "This script builds FDS and Smokeview apps and genrates a bundle using"
echo "specified fds and smv repo revisions or revisions from the latest firebot pass."
echo ""
echo "Options:"
echo "-f - force this script to run"
echo "-F - fds repo release"
echo "-S - smv repo release"
echo "-h - display this message"
echo "-H host - firebot host or LOCAL if revisions and documents are found at"
echo "          $HOME/.firebot/pass"
if [ "$MAILTO" != "" ]; then
  echo "-m mailto - email address [default: $MAILTO]"
else
  echo "-m mailto - email address"
fi
echo "-v - show settings used to build bundle"
exit 0
}

#-------------------- start of script ---------------------------------

FIREBOT_HOST="LOCAL"
MAILTO=
if [ "$EMAIL" != "" ]; then
  MAILTO=$EMAIL
fi
FDS_RELEASE=
SMV_RELEASE=
ECHO=

FORCE=

while getopts 'fF:hH:m:S:v' OPTION
do
case $OPTION  in
  f)
   FORCE="-f"
   ;;
  F)
   FDS_RELEASE="$OPTARG"
   ;;
  h)
   usage
   ;;
  H)
   FIREBOT_HOST="$OPTARG"
   ;;
  m)
   MAILTO="$OPTARG"
   ;;
  S)
   SMV_RELEASE="$OPTARG"
   ;;
  v)
   ECHO=echo
   ;;
esac
done
shift $(($OPTIND-1))


# Linux or OSX
JOPT="-J"
if [ "`uname`" == "Darwin" ] ; then
  JOPT=
fi

# both or neither RELEASE options must be set
BRANCH="test"
if [ "$FDS_RELEASE" != "" ]; then
  if [ "$SMV_RELEASE" != "" ]; then
    FDS_RELEASE="-x $FDS_RELEASE"
    SMV_RELEASE="-y $SMV_RELEASE"
    BRANCH="release"
  fi
fi
if [ "$FDS_RELEASE" == "" ]; then
  SMV_RELEASE=""
fi
if [ "$SMV_RELEASE" == "" ]; then
  FDS_RELEASE=""
fi
FIREBOT_BRANCH="-R $BRANCH"
BUNDLE_BRANCH="-b $BRANCH"

# get location of firebot files
FIREBOT_HOME=\~firebot
if [ "$FIREBOT_HOST" == "LOCAL" ]; then
  FIREBOT_HOME=\$HOME/.firebot/pass
fi

# email address
if [ "$MAILTO" != "" ]; then
  MAILTO="-m $MAILTO"
fi


curdir=`pwd`

# get apps and documents
cd ../Firebot
$ECHO ./run_firebot.sh $FORCE -c -C -B -g $FIREBOT_HOST -G $FIREBOT_HOME $JOPT $FDS_RELEASE $SMV_RELEASE $FIREBOT_BRANCH -T $MAILTO

# generate bundle
cd $curdir
$ECHO ./run_bundlebot.sh $FORCE $BUNDLE_BRANCH -p $FIREBOT_HOST -w -g
