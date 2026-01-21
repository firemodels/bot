#!/bin/bash

FDS_HASH=
SMV_HASH=
FDS_BRANCH=master
SMV_BRANCH=master

# uncomment following lines to build using specified hash and revisions

#FDS_HASH=ca0430f09b
#SMV_HASH=2f257722a
#FDS_BRANCH=master
#SMV_BRANCH=size64

# parameters for bundle

UPLOADBUNDLE=
if [ "`uname`" == "Darwin" ] ; then
  export FDS_OPENMPIDIR=/opt/openmpi415_oneapi22u3
  export intel_mpi_version=oneapi22u3
  export mpi_version=4.1.5
  export openmpi_dir=/opt/openmpi415_oneapi22u3
else
  export intel_mpi_version=2025.0
  export mpi_version_linux=INTEL
  export INTEL_MPI_VERSION=2025.0
  export MPI_VERSION=INTEL
fi

#define BUNDLE_MAILTO in .bashrc
if [ "$BUNDLE_MAILTO" != "" ]; then
  MAILTO=$BUNDLE_MAILTO
fi
#export INTEL_MPI_VERSION=2025.0
#export MPI_VERSION=INTEL



#---------------------------------------------
#                   usage
#---------------------------------------------

function usage {
echo ""
echo "BUILDnightly.sh usage"
echo ""
echo "This script builds FDS and Smokeview apps and generates a bundle using either the"
echo "specified fds and smv repo revisions or revisions from the latest firebot pass."
echo ""
echo "Options:"
echo "-B - install bundle after it is built"
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
echo "-U - upload bundle file to GitHub."
echo "-v - show settings used to build bundle"
exit 0
}

#-------------------- start of script ---------------------------------

commands=$0
DIR=$(dirname "${commands}")
cd $DIR
DIR=`pwd`

cd ../../..
repo=`pwd`

cd $DIR/output
outputdir=`pwd`
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
export TEST_VIRUS=

while getopts 'BcfhLm:o:r:R:TUv' OPTION
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
  T)
   TEST_VIRUS=1
   ;;
  U)
   UPLOADBUNDLE=-U
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
    echo "$0 already running."
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

#*** update webpages repos
if [ -d $repo/webpages ]; then
  echo updating webpages repo
  cd $repo/webpages
  get fetch origin              > $outputdir/update_webpages 2&>1
  git merge origin/nist-pages  >> $outputdir/update_webpages 2&>1
fi

# clone 3rd party repos
cd $curdir/../../Scripts
echo cloning hypre
./setup_repos.sh -K hypre > $outputdir/clone_hypre 2&>1 &
pid_clonehypre=$!

echo cloning sundials
./setup_repos.sh -K sundials > $outputdir/clone_sundials 2&>1 &
pid_clonesundials=$!

cd $curdir
pid_clonefds=
pid_clonesmv=
pid_cloneall=
if [ "$BRANCH" == "nightly" ]; then
# a nightly bundle - clone fds and smv repos
  echo cloning fds
  ./clone_repo.sh -F -N -r $FDS_HASH > $outputdir/clone_fds 2&>1 &
  pid_clonefds=$!

  echo cloning smv
  ./clone_repo.sh -S -N -r $SMV_HASH > $outputdir/clone_smv 2&>1 &
  pid_clonesmv=$!
else
#a release bundle - clone all repos except for bot
  echo cloning all repos 
  ./clone_all_repos.sh  $outputdir > $outputdir/clone_all 2&>1 &
  pid_cloneall=$!
  FDS_TAG="-X $BUNDLE_FDS_TAG"
  SMV_TAG="-Y $BUNDLE_SMV_TAG"
fi

wait $pid_clonehypre
echo hypre cloned

wait $pid_clonesundials
echo sundials cloned

if [ "$pid_clonefds" != "" ]; then
  wait $pid_clonefds
  echo fds cloned

fi
if [ "$pid_clonesmv" != "" ]; then
  wait $pid_clonesmv
  echo sundials cloned
fi
if [ "$pid_cloneall" != "" ]; then
  wait $pid_cloneall
  echo all repos clone complete
fi

./make_fdsapps.sh &
pid_fdsapps=$1

./make_smvapps.sh &
pid_smvapps=$!

wait $pid_fdsapps
wait $pid_smvapps

echo $FDS_HASH     > $repo/bot/Bundlebot/nightly/apps/FDS_HASH
echo $SMV_HASH     > $repo/bot/Bundlebot/nightly/apps/SMV_HASH
echo $FDS_REVISION > $repo/bot/Bundlebot/nightly/apps/FDS_REVISION
echo $SMV_REVISION > $repo/bot/Bundlebot/nightly/apps/SMV_REVISION

#*** generate and upload bundle
cd $curdir
$ECHO ./bundlebot.sh $FORCE $BUNDLE_BRANCH $INSTALL $FDS_TAG $SMV_TAG -w $UPLOADBUNDLE
rm $LOCKFILE
