#!/bin/bash
export NOPAUSE=1
args=$0
DIR=$(dirname "${args}")
cd $DIR

source ./GET_ENV.sh bot

BUNDLE_HOME=$HOME/.bundle

mkdir -p $BUNDLE_HOME/pubs
mkdir -p $BUNDLE_HOME/BUNDLE
mkdir -p $BUNDLE_HOME/OPENMPI

if [ -e $BUNDLE_HOME/FDS_SMV_ENV.sh ]; then
  source $BUNDLE_HOME/FDS_SMV_ENV.sh
else
  echo "***error: parameter file $BUNDLE_HOME/FDS_SMV_ENV.sh"
  echo "          does not exist"
fi
scriptdir=`dirname "$(readlink "$0")"`
curdir=`pwd`
cd $scriptdir/../../../..
repo_root=`pwd`

cd $repo_root/fds
export fds_version=`git describe --long --dirty`
cd $repo_root/smv
export smv_version=`git describe --long --dirty`
cd $curdir

# get apps

# get pubs

./get_pubs.sh firebot  $firebothome/.firebot/pubs   $linux_hostname
./get_pubs.sh smokebot $smokebothome/.smokebot/pubs $linux_hostname

# build bundle

./bundle_generic.sh    $fds_version $smv_version $linux_mpi_version

