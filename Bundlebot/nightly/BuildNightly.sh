#!/bin/bash

UPLOAD=-g
FDS_HASH=
SMV_HASH=
FDS_RELEASE=
SMV_RELEASE=
FDS_BRANCH=master
SMV_BRANCH=master

# uncomment following lines to build using specified hash and revisions

#UPLOAD=
#FDS_HASH=ca0430f09b
#SMV_HASH=2f257722a
#FDS_RELEASE=FDS-6.10.1-1509
#SMV_RELEASE=SMV-6.10.5-249
#FDS_BRANCH=master
#SMV_BRANCH=size64

# parameters for bundle

if [ "`uname`" == "Darwin" ] ; then
  export FDS_OPENMPIDIR=/opt/openmpi414_oneapi1p6
  export intel_mpi_version=oneapi1p6
  export mpi_version=4.1.4
  export openmpi_dir=/opt/openmpi414_oneapi1p6
else
  export intel_mpi_version=2025.0
  export mpi_version_linux=INTEL
fi

#define BUNDLE_MAILTO in .bashrc
if [ "$BUNDLE_MAILTO" != "" ]; then
  MAILTO=$BUNDLE_MAILTO
fi
export INTEL_MPI_VERSION=2025.0
export MPI_VERSION=INTEL



#---------------------------------------------
#                   usage
#---------------------------------------------

function usage {
echo ""
echo "BUILD_fdssmv_nightly.sh usage"
echo ""
echo "This script builds FDS and Smokeview apps and generates a bundle using either the"
echo "specified fds and smv repo revisions or revisions from the latest firebot pass."
echo ""
echo "Options:"
echo "-b - use existing bot branch"
echo "-c - bundle without warning about cloning/erasing fds and smv repos"
echo "-f - force this script to run"
echo "-h - display this message"
echo "-L - build apps using latest revision"
if [ "$MAILTO" != "" ]; then
  echo "-m mailto - email address [default: $MAILTO]"
else
  echo "-m mailto - email address"
fi
echo "-o - specify GH_OWNER when building a bundle. [default: $GH_OWNER]"
echo "-r - specify GH_REPO when building a bundle. [default: $GH_REPO]"
echo "-R branch - clone repos using name branch {default: $BRANCH]"
echo "-r - create a release bundle (same as -R branc)"
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

commands=$0
DIR=$(dirname "${commands}")
cd $DIR
DIR=`pwd`

cd ../../..
repo=`pwd`

cd $DIR

LOCKFILE=$HOME/.bundle/lock

MAILTO=
if [ "$BUNDLE_EMAIL" != "" ]; then
  MAILTO=$BUNDLE_EMAIL
fi
ECHO=
PROCEED=

FORCE=
RELEASE=
BRANCH=nightly
FDS_TAG=
SMV_TAG=
LATEST=
INSTALL=

while getopts 'BcfhLm:o:r:R:Uv' OPTION
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
  U)
   UPLOAD=
   ;;
  v)
   ECHO=echo
   ;;
esac
done
shift $(($OPTIND-1))

if [ "`uname`" == "Darwin" ] ; then
  platform=osx
  JOPT=
else
  JOPT="-J"
  platform=lnx
fi

if [ "$BRANCH" == "nightly" ]; then
  FDS_TAG=
  SMV_TAG=
  $repo/bot/Firebot/getGHfile.sh     FDS_INFO.txt
  FDS_HASH=`grep FDS_HASH  FDS_INFO.txt | awk '{print $2}'`
  SMV_HASH=`grep SMV_HASH  FDS_INFO.txt | awk '{print $2}'`
  FDS_REVISION=`grep FDS_REVISION  FDS_INFO.txt | awk '{print $2}'`
  SMV_REVISION=`grep SMV_REVISION  FDS_INFO.txt | awk '{print $2}'`
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
if [ "$INTEL_MPI_VERSION" != "" ]; then
echo "       Intel mpi version: $INTEL_MPI_VERSION"
fi
echo "             MPI version: $MPI_VERSION"
if [ "$MAILTO" != "" ]; then
echo "                   EMAIL: $MAILTO_ARG"
fi
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

#*** update wiki and webpages repos
if [ "$ECHO" == "" ]; then
  UPDATE_REPO webpages nist-pages || exit 1
fi

# clone fds and smv repos
if [ "$BRANCH" == "nightly" ]; then
  cd $curdir
  ./clone_repo.sh -F -N -r $FDS_HASH
  ./clone_repo.sh -S -N -r $SMV_HASH
fi

#clone all repos except for bot
if [ "$BRANCH" != "nightly" ]; then
  cd $curdir
  ./clone_all_repos.sh
  FDS_TAG="-X $BUNDLE_FDS_TAG"
  SMV_TAG="-Y $BUNDLE_SMV_TAG"
fi

./make_apps.sh
echo $FDS_HASH     > $repo/bot/Bundlebot/nightly/apps/FDS_HASH
echo $SMV_HASH     > $repo/bot/Bundlebot/nightly/apps/SMV_HASH
echo $FDS_REVISION > $repo/bot/Bundlebot/nightly/apps/FDS_REVISION
echo $SMV_REVISION > $repo/bot/Bundlebot/nightly/apps/SMV_REVISION

#*** generate and upload bundle
cd $curdir
$ECHO ./bundlebot.sh $FORCE $BUNDLE_BRANCH $INSTALL $FDS_TAG $SMV_TAG -w $UPLOAD
rm $LOCKFILE
