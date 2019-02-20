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
git clean -dxf >& /dev/null
echo "*** building FDS" 
#./make_fds.sh >& /dev/null

echo "*** building fds2ascii"
cd ../../Utilities/fds2ascii/intel_${platform}_64
git clean -dxf >& /dev/null
./make_fds2ascii.sh >& /dev/null

echo "*** building test_mpi"
cd ../../../Utilities/test_mpi/${MPI}_intel_${platform}
git clean -dxf >& /dev/null
./make_test_mpi.sh >& /dev/null

echo "*** fds builds complete"

cd $CURDIR


