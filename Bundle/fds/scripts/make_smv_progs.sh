#!/bin/bash

if [ "`uname`" == "Darwin" ]; then
  platform=intel_osx_64
else
  platform=intel_linux_64
fi

BUILD()
{
  dir=$1
  platform=intel_linux_64
  script=make_${dir}.sh

  echo "*** building $dir"
  cd $dir/$platform
  ./$script >& /dev/null
  cd $BUILDDIR
}

CURDIR=`pwd`

cd ../../../../smv/Source
git clean -dxf >& /dev/null

cd ../Build
git clean -dxf >& /dev/null

BUILDDIR=`pwd`

BUILD LIBS
BUILD background
BUILD dem2fds
BUILD hashfile
BUILD smokediff
BUILD smokezip
BUILD wind2fds
BUILD smokeview
echo "*** smokeview builds complete"
