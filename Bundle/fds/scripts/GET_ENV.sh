#!/bin/bash
option=$1

BUNDLE_HOME=$HOME/.bundle

mkdir -p $BUNDLE_HOME/pubs
mkdir -p $BUNDLE_HOME/BUNDLE
mkdir -p $BUNDLE_HOME/OPENMPMI

# this script is run from a script in bot/Bundle/fds/linux or
# bot/Bundle/fds/osx

if [ "$option" == "web" ]; then
  if [ -e $BUNDLE_HOME/FDS_SMV_ENVpc.sh ]; then
    source $BUNDLE_HOME/FDS_SMV_ENVpc.sh
  else
    echo "***error: parameter file $BUNDLE_HOME/FDS_SMV_ENVpc.sh"
    echo "          does not exist"
  fi
fi
if [ "$option" == "bot" ]; then
  if [ -e $BUNDLE_HOME/FDS_SMV_ENV.sh ]; then
    source $BUNDLE_HOME/FDS_SMV_ENV.sh
  else
    echo "***error: parameter file $BUNDLE_HOME/FDS_SMV_ENV.sh"
    echo "          does not exist"
  fi
fi

if [ "$option" == "bot" ]; then
  CURDIR=`pwd`
  cd $firebotrepo/fds
  export fds_version=`git describe --long --dirty`
  cd $firebotrepo/smv
  export smv_version=`git describe --long --dirty`
  cd $CURDIR
fi

../scripts/CHECK_VARS.sh

