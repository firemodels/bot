#!/bin/bash
bot_host=$1
firebot_home=$2
smokebot_home=$3
mpi_version=$4

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

cd $repo_root/fds
export fds_version=`git describe --long --dirty`
cd $repo_root/smv
export smv_version=`git describe --long --dirty`
cd $curdir

# copy apps from fds/smv repo to $HOME/.bundle/apps

./copy_apps.sh firebot
./copy_apps.sh smokebot

# copy pubs from the firebot/smokebot account to $HOME/.bundle/pubs

./copy_pubs.sh firebot  $firebot_home/.firebot/pubs   $bot_host
./copy_pubs.sh smokebot $smokebot_home/.smokebot/pubs $bot_host

# build bundle

./bundle_generic.sh    $fds_version $smv_version $mpi_version

