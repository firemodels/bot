#!/bin/bash

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
echo "-X fdstag - when cloning, tag fds repo with fdstag"
echo "-Y smvtag - when cloning, tag smv repo with smvtag"

if [ "$MAILTO" != "" ]; then
  echo "-m mailto - email address [default: $MAILTO]"
else
  echo "-m mailto - email address"
fi

echo "-L - build apps using latest revision"
echo "-o - specify GH_OWNER when building a bundle. [default: $GH_OWNER]"
echo "-r - specify GH_REPO when building a bundle. [default: $GH_REPO]"
echo "-R branch - clone repos using name branch"
echo "-r - create a release bundle (same as -R branc)"
echo "-S - smv repo hash/release"
echo "-U - do not upload bundle file."
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
LOCKFILE=$HOME/.bundle/lock

MAILTO=
if [ "$BUNDLE_EMAIL" != "" ]; then
  MAILTO=$BUNDLE_EMAIL
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
FDS_TAG=
SMV_TAG=
LATEST=
INSTALL=

while getopts 'BcfF:hLm:o:r:R:S:UvX:Y:' OPTION
do
case $OPTION  in
  B)
   INSTALL="-B"
   ;;
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
  L)
   LATEST=1
   ;;
  m)
   MAILTO="$OPTARG"
   ;;
  o)
   export GH_OWNER="$OPTARG"
   ;;
  r)
   export GH_REPO="$OPTARG"
   ;;
  R)
   BRANCH="$OPTARG"
   ;;
  S)
   SMV_RELEASE="$OPTARG"
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
  platform=osx
  JOPT=
else
  platform=lnx
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
echo "          Firebot branch: $FIREBOT_BRANCH_ARG"
echo "       Intel mpi version: $INTEL_MPI_VERSION"
echo "             MPI version: $MPI_VERSION"
if [ "$OPENMPI_DIR" ]; then
  echo "             OpenMPI dir: $OPENMPI_DIR"
fi
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
echo "------------------------------------------------------------"
echo ""

if [ -e $LOCKFILE ]; then
  if [ "$FORCE" == "" ]; then
    echo "run_bundlebot.sh script already running."
    echo "If this is not the case, rerun using the -f option"
    exit
  fi
fi
touch $LOCKFILE

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

cd ../../..
repo=`pwd`

cd $DIR

#*** update bot and webpages repos
if [ "$ECHO" == "" ]; then
  UPDATE_REPO bot      master     || exit 1
  UPDATE_REPO webpages nist-pages || exit 1
fi

#*** build apps
cd $curdir
cd $repo/bot/Firebot
if [ "$platform" == "osx" ]; then
# remove || exit 1 until compiler warnings are removed
$ECHO ./run_firebot.sh -a $FORCE -c -C -B -F $JOPT $FDS_RELEASE $FDS_TAG $SMV_RELEASE $SMV_TAG $FIREBOT_BRANCH -T $MAILTO
else
$ECHO ./run_firebot.sh -a $FORCE -c -C -B -F $JOPT $FDS_RELEASE $FDS_TAG $SMV_RELEASE $SMV_TAG $FIREBOT_BRANCH -T $MAILTO || exit 1
fi

#*** generate and upload bundle
cd $curdir
$ECHO ./bundlebot.sh $FORCE $BUNDLE_BRANCH $FDS_RELEASE $INSTALL $FDS_TAG $SMV_RELEASE $SMV_TAG -w $UPLOAD
rm $LOCKFILE
