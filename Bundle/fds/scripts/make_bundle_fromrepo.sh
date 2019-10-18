#!/bin/bash

export NOPAUSE=1
args=$0
DIR=$(dirname "${args}")

# get fds repo revision
cd $DIR
fdsrepo=../../../../fds
cd $fdsrepo
FDSREV=`git describe --abbrev`

# get smv repo revision
cd $DIR
smvrepo=../../../../smv
cd $smvrepo
SMVREV=`git describe --abbrev`

# linux
intel_mpi_version=19u4 
mpi_version=INTEL

# OSX
if [ "`uname`" == "Darwin" ]; then
  intel_mpi_version=19u4 
  mpi_version=3.1.2
fi

cd $DIR
echo ./bundle_generic.sh $FDSREV $SMVREV $mpi_version $intel_mpi_version
./bundle_generic.sh $FDSREV $SMVREV $mpi_version $intel_mpi_version
