#!/bin/bash

#---------------------------------------------
#                   SETENV
#---------------------------------------------

SETENV ()
{
  local var=$1
  local bashvar=$2

  if [ "\$$bashvar" != "" ]; then
    eval $var=\$$bashvar
  fi
}

# define variables in startup file if not passed into this script

build_apps=
GET_BOT_REVISION=
SETENV bot_host      BOT_HOST
SETENV firebot_home  FIREBOT_HOME
SETENV smokebot_home SMOKEBOT_HOME
SETENV mpi_version   MPI_VERSION

#---------------------------------------------
#                   DEFAULT
#---------------------------------------------

function DEFAULT {
  arg=$1
  DEF=
  if [ "$arg" != "" ]; then
    DEF="[default: $arg]"
  fi
}


#---------------------------------------------
#                   usage
#---------------------------------------------

function usage {
echo "make_bundle_bot.sh [options]"
echo "   Build a bundle using documents built by firebot and smokebot"
echo "   and applications built by firebot
echo ""
echo "Options:"
echo "-B - build fds and smokeview apps"

DEFAULT $bot_host
echo "-b - host where firebot and smokebot are located $DEF"

DEFAULT $firebot_home
echo "-f - firebot home directory $DEF"

echo "-h - display this message"

DEFAULT $mpi_version
echo "-m - mpi type (INTEL or openmpi version number) $DEF"

echo "-r - build bundle using fds and smv revision from last firebot pass"
DEFAULT $smokebot_home
echo "-s - smokebot home directory $DEF"
exit
}

#*** parse command line options

while getopts 'b:Bf:hm:rs:' OPTION
do
case $OPTION  in
  b)
   bot_host=$OPTARG
   ;;
  B)
   build_apps=1
   ;;
  f)
   firebot_home=$OPTARG
   ;;
  h)
   usage;
   ;;
  m)
   mpi_version=$OPTARG
   ;;
  r)
   GET_BOT_REVISION=1
   ;;
  s)
   smokebot_home=$OPTARG
   ;;
esac
done
shift $(($OPTIND-1))

export NOPAUSE=1
args=$0
DIR=$(dirname "${args}")
cd $DIR

BUNDLE_HOME=$HOME/.bundle

mkdir -p $BUNDLE_HOME/pubs
mkdir -p $BUNDLE_HOME/BUNDLE
mkdir -p $BUNDLE_HOME/OPENMPI

scriptdir=`dirname "$(readlink "$0")"`
curdir=`pwd`
cd $scriptdir/../../../..
repo_root=`pwd`

if [ "$build_apps" == "1" ]; then

# set revision in fds and smv repos to last one passed in firebot
  if [ "$GET_BOT_REVISION" == "1" ]; then
    cd $repo_root/bot/Bundle/fds/scripts
    ./set_firebot_revisions.sh -b $bot_host -f $firebot_home  || exit 1
  fi

# build fds and smv apps
  cd $repo_root/bot/Firebot
  ./run_firebot.sh -c -b -B
  error_status=$?

  if [ "$GET_BOT_REVISION" == "1" ]; then
# set revision in fds and smv repos back to master
    cd $repo_root/bot/Bundle/fds/scripts
    ./set_firebot_revisions.sh -m
  fi
fi

cd $repo_root/fds
export fds_version=`git describe --long --dirty`
cd $repo_root/smv
export smv_version=`git describe --long --dirty`
cd $curdir

# copy apps from fds/smv repo to $HOME/.bundle/fds and $HOME/.bundle/smv

cd $repo_root/bot/Firebot
./copy_apps.sh

# copy pubs from the firebot/smokebot account to $HOME/.bundle/pubs

cd $curdir
./copy_pubs.sh firebot  $firebot_home/.firebot/pubs   $bot_host || exit 1
./copy_pubs.sh smokebot $smokebot_home/.smokebot/pubs $bot_host || exit 1

# build bundle

./bundle_generic.sh    $fds_version $smv_version $mpi_version

