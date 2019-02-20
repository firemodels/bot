#!/bin/bash

if [ "`uname`" == "Darwin" ]; then
  platform=osx
  MPI=mpi
else
  platform=linux
  MPI=impi
fi

echo

CURDIR=`pwd`

cd ../../../../fds/Build/${MPI}_intel_${platform}_64
git clean -dxf
echo "*** building FDS" 
./make_fds.sh

echo "*** building fds2ascii"
cd ../../Utilities/fds2ascii/intel_${platform}_64
git clean -dxf
./make_fds2ascii.sh

echo "***building test_mpi"
cd ../../../Utilities/test_mpi/${MPI}_intel_${platform}
git clean -dxf
./make_test_mpi.sh

echo "*** fds builds complete"

cd $CURDIR


