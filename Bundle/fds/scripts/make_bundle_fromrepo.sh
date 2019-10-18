#!/bin/bash

#*** Linux parameters

intel_mpi_version_linux=19u4
mpi_version_linux=INTEL

#*** OSX parameters

intel_mpi_version_osx=19u4
mpi_version_osx=3.1.2

# determine platform script is running on

if [ "`uname`" == "Darwin" ]; then
  intel_mpi_version=$intel_mpi_version_osx
  mpi_version=$mpi_version_osx
else
  intel_mpi_version=$intel_mpi_version_linux
  mpi_version=$mpi_version_linux
fi

source ~/.bundle/bundle_setup.sh
./copy_pubs.sh firebot  $firebot_home/.firebot/pubs   $firebot_host
./copy_pubs.sh smokebot $smokebot_home/.smokebot/pubs $smokebot_host
./copy_apps.sh firebot  $firebot_home/.firebot/fds    $firebot_host
./copy_apps.sh smokebot $firebot_home/.smokebot/smv   $smokebot_host

export NOPAUSE=1
args=$0
DIR=$(dirname "${args}")
cd $DIR
DIR=`pwd`

# get fds repo revision
cd $DIR
fdsrepo=../../../../fds
cd $fdsrepo
FDSREV=`git describe --abbrev | awk -F '-' '{print $1"-"$2}'`

# get smv repo revision
cd $DIR
smvrepo=../../../../smv
cd $smvrepo
SMVREV=`git describe --abbrev | awk -F '-' '{print $1"-"$2}'`

cd $DIR
echo ./bundle_generic.sh $FDSREV $SMVREV $mpi_version $intel_mpi_version
./bundle_generic.sh $FDSREV $SMVREV $mpi_version $intel_mpi_version
