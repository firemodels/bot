#!/bin/bash
option=$1

BUNDLE_HOME=$HOME/.bundle

mkdir -p $BUNDLE_HOME/pubs
mkdir -p $BUNDLE_HOME/BUNDLE
mkdir -p $BUNDLE_HOME/OPENMPI

# this script is run from a script in bot/Bundle/fds/linux or
# bot/Bundle/fds/osx

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

../scripts/CHECK_VARS.sh

