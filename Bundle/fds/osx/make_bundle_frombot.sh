#!/bin/bash
export NOPAUSE=1
args=$0
DIR=$(dirname "${args}")
cd $DIR

BUNDLE_HOME=$HOME/.bundle

mkdir -p $BUNDLE_HOME/pubs
mkdir -p $BUNDLE_HOME/BUNDLE
mkdir -p $BUNDLE_HOME/OPENMPMI

if [ -e $BUNDLE_HOME/FDS_SMV_ENV.sh ]; then
  source $BUNDLE_HOME/FDS_SMV_ENV.sh
else
  echo "***error: parameter file $BUNDLE_HOME/FDS_SMV_ENV.sh"
  echo "          does not exist"
  exit
fi

CURDIR=`pwd`
cd ../../../../fds
scp $linux_hostname:.firebot/history/fds_hash .
git checkout `cat fds_hash`
export fds_version=`git describe --long --dirty`

cd ../smv
scp $linux_hostname:.firebot/history/smv_hash .
git checkout `cat smv_hash`
export smv_version=`git describe --long --dirty`
cd $CURDIR

cd ../../..
export REPO_ROOT=`pwd`
export fds_smvroot=$osx_svn_root
export bundlebase=${fds_version}-${smv_version}_osx64
export MPI_VERSION=$osx_mpi_version

./get_fds_pubs.sh $linux_hostname $firebothome  $GUIDE_DIR
./get_smv_pubs.sh $linux_hostname $smokebothome $GUIDE_DIR
../scripts/bundle_generic.sh

