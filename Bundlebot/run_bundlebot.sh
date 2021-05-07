 #!/bin/bash

if [ "`uname`" == "Darwin" ] ; then

#*** OSX parameters

  export FDS_OPENMPIDIR=/opt/openmpi410_oneapi_64
fi

#---------------------------------------------
#                   usage
#---------------------------------------------

function usage {
echo ""
echo "run_bundlebot.sh usage"
echo ""
echo "This script builds FDS and Smokeview apps and generates a bundle using either the"
echo "specified fds and smv repo revisions or revisions from the latest firebot pass."
echo ""
echo "Options:"
echo "-c - bundle without warning about cloning/erasing fds and smv repos"
echo "-f - force this script to run"
echo "-F - fds repo hash/release"
echo "-h - display this message"
echo "-p host -  host containing pubs"
echo "           firebot/fds pubs: ~firebot/.firebot/pubs"
echo "           smokebot/smv pubs: ~smokebot/.smokebot/pubs"
echo "           user generated pubs: $HOME/.bundle/manuals (host=LOCAL)"
echo "-X fdstag - when cloning, tag fds repo with fdstag"
echo "-Y smvtag - when cloning, tag smv repo with smvtag"

FIREBOT_HOST_MSSG=
if [ "$FIREBOT_HOST" != "" ]; then
  FIREBOT_HOST_MSSG="[default: $FIREBOT_HOST]"
fi
echo "-H host - firebot/smokebot host $FIREBOT_HOST_MSSG"

if [ "$MAILTO" != "" ]; then
  echo "-m mailto - email address [default: $MAILTO]"
else
  echo "-m mailto - email address"
fi

echo "-r - create a release bundle"
echo "-S - smv repo hash/release"
echo "-U - do not upload bundle file."
echo "     By default the bundle is uploaded to a Google drive "
echo "     directory with id found in the file:"
echo "     $HOME/.bundle/GOOGLE_DIR_ID"
echo "-v - show settings used to build bundle"
exit 0
}

#---------------------------------------------
#                   CHK_REPO
#---------------------------------------------

CHK_REPO ()
{
  local repodir=$1

  if [ ! -e $repodir ]; then
     echo "***error: the repo directory $repodir does not exist."
     echo "          Aborting the make_bundle script"
     return 1
  fi
  return 0
}

#---------------------------------------------
#                   CD_REPO
#---------------------------------------------

CD_REPO ()
{
  local repodir=$1
  local branch=$2

  CHK_REPO $repodir || return 1

  cd $repodir
  if [ "$branch" != "current" ]; then
  if [ "$branch" != "" ]; then
     CURRENT_BRANCH=`git rev-parse --abbrev-ref HEAD`
     if [ "$CURRENT_BRANCH" != "$branch" ]; then
       echo "***error: was expecting branch $branch in repo $repodir."
       echo "Found branch $CURRENT_BRANCH. Aborting firebot."
       return 1
     fi
  fi
  fi
  return 0
}
#---------------------------------------------
#                   update_repo
#---------------------------------------------

UPDATE_REPO()
{
   local reponame=$1
   local branch=$2

   CD_REPO $repo/$reponame $branch || return 1

   echo Updating $branch on repo $repo/$reponame
   git fetch origin
   git merge origin/$branch
   return 0
}


#-------------------- start of script ---------------------------------

if [ -e $HOME/.bundle/bundle_config.sh ]; then
  source $HOME/.bundle/bundle_config.sh
else
  echo ***error: configuration file $HOME/.bundle/bundle_config.sh is not defined
  exit 1
fi
FIREBOT_HOST=$bundle_hostname
FIREBOT_HOME=$bundle_firebot_home

MAILTO=
if [ "$EMAIL" != "" ]; then
  MAILTO=$EMAIL
fi
FDS_RELEASE=
SMV_RELEASE=
ECHO=
PROCEED=
UPLOAD=-g

FORCE=
RELEASE=
BRANCH=nightly
FDS_HASH=
SMV_HASH=
PUB_HOST=$FIREBOT_HOST
FDS_TAG=
SMV_TAG=

while getopts 'cCfF:hH:m:p:rS:UvX:Y:' OPTION
do
case $OPTION  in
  c)
   PROCEED=1
   ;;
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
  p)
   PUB_HOST="$OPTARG"
   ;;
  S)
   SMV_RELEASE="$OPTARG"
   ;;
  r)
   BRANCH=release
   ;;
  U)
   UPLOAD=
   ;;
  v)
   ECHO=echo
   ;;
  X)
   FDS_TAG="$OPTARG"
   ;;
  Y)
   SMV_TAG="$OPTARG"
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
FDS_RELEASE_ARG=$FDS_RELEASE
SMV_RELEASE_ARG=$SMV_RELEASE
if [ "$FDS_RELEASE" != "" ]; then
  if [ "$SMV_RELEASE" != "" ]; then
    FDS_RELEASE="-x $FDS_RELEASE"
    SMV_RELEASE="-y $SMV_RELEASE"
  fi
fi
if [ "$FDS_RELEASE" == "" ]; then
  SMV_RELEASE=""
  SMV_RELEASE_ARG=""
fi
if [ "$SMV_RELEASE" == "" ]; then
  FDS_RELEASE=""
  FDS_RELEASE_ARG=""
fi

if [ "$FDS_TAG" != "" ]; then
  FDS_TAG_ARG=$FDS_TAG
  FDS_TAG="-X $FDS_TAG"
fi
if [ "$SMV_TAG" != "" ]; then
  SMV_TAG_ARG=$SMV_TAG
  SMV_TAG="-Y $SMV_TAG"
fi

FIREBOT_BRANCH_ARG=$BRANCH
FIREBOT_BRANCH="-R $BRANCH"
BUNDLE_BRANCH="-b $BRANCH"

# email address
MAILTO_ARG=$MAILTO
if [ "$MAILTO" != "" ]; then
  MAILTO="-m $MAILTO"
fi

echo ""
echo "------------------------------------------------------------"
echo "            Firebot host: $FIREBOT_HOST"
echo "  Firebot home directory: $FIREBOT_HOME"
if [ "$FDS_TAG_ARG" != "" ]; then
  echo "                 FDS TAG: $FDS_TAG_ARG"
fi
if [ "$FDS_RELEASE_ARG" != "" ]; then
  echo "            FDS Revision: $FDS_RELEASE_ARG"
fi
if [ "$SMV_TAG_ARG" != "" ]; then
  echo "                 SMV TAG: $SMV_TAG_ARG"
fi
if [ "$SMV_RELEASE_ARG" != "" ]; then
  echo "            SMV Revision: $SMV_RELEASE_ARG"
fi
echo "                   EMAIL: $MAILTO_ARG"
echo "          Firebot branch: $FIREBOT_BRANCH_ARG"
echo "------------------------------------------------------------"
echo ""

curdir=`pwd`

if [ "$PROCEED" == "" ]; then
  echo ""
  echo "------------------------------------------------------------"
  echo "------------------------------------------------------------"
  echo "You are about to erase and then clone the fds and smv repos."
  echo "Press any key to continue or <CTRL> c to abort."
  echo "To avoid this warning, use the -c option on the command line"
  echo "------------------------------------------------------------"
  echo "------------------------------------------------------------"
  read val
fi

commands=$0
DIR=$(dirname "${commands}")
cd $DIR
DIR=`pwd`

cd ../..
repo=`pwd`

cd $DIR

#*** update bot and webpages repos
UPDATE_REPO bot      master     || exit 1
UPDATE_REPO webpages nist-pages || exit 1

#*** build apps
cd $curdir
cd ../Firebot
$ECHO ./run_firebot.sh $FORCE -c -C -B -g $FIREBOT_HOST -G $FIREBOT_HOME $JOPT $FDS_RELEASE $FDS_TAG $SMV_RELEASE $SMV_TAG $FIREBOT_BRANCH -T $MAILTO || exit 1

#*** generate and upload bundle
cd $curdir
$ECHO ./bundlebot.sh $FORCE $BUNDLE_BRANCH -p $PUB_HOST $FDS_RELEASE $FDS_TAG $SMV_RELEASE $SMV_TAG -w $UPLOAD
