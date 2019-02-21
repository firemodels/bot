#!/bin/bash
build_apps=$1
bot_host=$2
firebot_home=$3
smokebot_home=$4
mpi_version=$5

#---------------------------------------------
#                   SETENV
#---------------------------------------------

SETENV ()
{
  local var=$1
  local bashvar=$2

  if [ "\$$bashvar" != "" ]; then
    eval $var=\$$bashvar
  else
    echo ***error: the environment variable $bashvar does not exist
    echo "         it needs to be defined in your startup file"
  fi
}

# define variables in startup file if not passed into this script

if [ "$bot_host" == "" ]; then
  SETENV bot_host      BOT_HOST
  SETENV firebot_home  FIREBOT_HOME
  SETENV smokebot_home SMOKEBOT_HOME
  SETENV mpi_version   MPI_VERSION
fi

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
  cd $repo_root/bot/Firebot
  ./run_firebot.sh -c -u -B
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
./copy_pubs.sh firebot  $firebot_home/.firebot/pubs   $bot_host
./copy_pubs.sh smokebot $smokebot_home/.smokebot/pubs $bot_host

# build bundle

./bundle_generic.sh    $fds_version $smv_version $mpi_version

