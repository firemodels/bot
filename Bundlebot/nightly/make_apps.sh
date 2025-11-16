#!/bin/bash

# -------------------------------------------------------------

BUILDFDS()
{
  echo ***building fds
  echo ""                >& $compilelog 
  echo "***************" >& $compilelog 

  echo "***building fds" >& $compilelog 
  cd $fdsrepo/Build/impi_intel_$platform
  ./make_fds bot >& $compilelog 

  echo "***building fds openmp"
  echo "***building fds openmp" >& $compilelog 
  cd $fdsrepo/Build/impi_intel_$platform_openmp
  ./make_fds bot >& $compilelog 
}

# -------------------------------------------------------------

CHECK_BUILDFDS()
{
  if [ ! -e $fdsrepo/Build/impi_intel_$platform/fds_impi_intel_$platform ]; then
    echo "***error: The program fds_impi_$platform failed to build"
    echo "***error: The program fds_impi_$platform failed to build"  >& $errorlog 
  fi
}

# -------------------------------------------------------------

CHECK_BUILDFDSOPENMP()
{
  if [ ! -e $fdsrepo/Build/impi_intel_$platform_openmp/fds_impi_intel_$platform_openmp ]; then
    echo "***error: The program fds_impi_$platform_openmp failed to build"
    echo "***error: The program fds_impi_$platform_openmp failed to build"  >& $errorlog 
  fi
}

# -------------------------------------------------------------

BUILDUTIL()
{
  prog=$1
  builddir=$2

  echo "***building $prog"
  echo ""                  >& $compilelog 
  echo "***************"   >& $compilelog 
  echo "***building $prog" >& $compilelog 
  cd $fdsrepo/Utilities/$prog/$builddir
  ./make_$prog bot >& $compilelog 
}

# -------------------------------------------------------------

CHECK_BUILDTESTMPI()
{
  if [ ! -e $fdsrepo/Utilities/test_mpi/impi_intel_$platform/test_mpi.exe ]; then
    echo "***error: The program test_mpi.exe failed to build"
    echo "***error: The program test_mpi.exe failed to build"  >& $errorlog
  fi
}

# -------------------------------------------------------------

CHECK_BUILDUTIL()
{
  prog=$1
  builddir=$2
  suffix=$3

  if [ ! -e $fdsrepo/Utilities/$prog/$builddir/$prog_$builddir ]; then
    echo "***error: The program $prog_$builddir failed to build
    echo "***error: The program $prog_$builddir failed to build  >& $errorlog
  fi
}

# -------------------------------------------------------------

BUILDLIB()
{
  echo "***building smokeview libraries"
  echo.""                >& $compilelog 
  echo "***************" >& $compilelog 
  echo "***building smokeview libraries" >& $compilelog 

  cd $smvrepo/Build/LIBS/intel_$platform$SMVSIZE
  ./make_LIBS_bot >& $compilelog 
}

# -------------------------------------------------------------
CHECK_BUILDSMV()
{
  if [ ! -e $smvrepo/Build/smokeview/intel_$platform$SMVSIZE/smokeview_$platform$SMVSIZE]; then
    echo "***error: The program smokeview_$platform_64 failed to build"
    echo "***error: The program smokeview_$platform_64 failed to build"  >& $errorlog 
  fi
}

# -------------------------------------------------------------
BUILD()
{
  prog=$1
  script=make_$prog

  echo "***building $prog"
  echo ""                >& $compilelog 
  echo "***************" >& $compilelog 
  echo "***building $prog" >& $compilelog 
  cd $smvrepo/Build/$prog/intel_$platform$SMVSIZE
  call $script bot >& $compilelog 
}

# -------------------------------------------------------------

CHECK_BUILD()
{
  prog=$1

  if [ ! -e $smvrepo/Build/%prog%/intel_$platform$SMVSIZE/$prog_$platform$SMVSIZE ]; then
    echo "***error: The program %prog%_$platform_64.exe failed to build"
    echo "***error: The program %prog%_$platform_64.exe failed to build"  >& $errorlog
  fi
}
platform=linux
if [ "`uname`" == "Darwin" ] ; then
  platform="osx"
fi

SMVSIZE=_64
CURDIR=`pwd`

git clean -dxf  >& /dev/null

clean_log=$CURDIR/output/clean.log
compile_log=$CURDIR/output/compile.log
error_log=$CURDIR/output/error.log

echo > $clean_log
echo > $compile_log
echo > $error_log

cd ../../..
REPOROOT=`pwd`

cd $REPOROOT/smv
smvrepo=`pwd`

cd $REPOROOT%/fds
fdsrepo=`pwd`

cd $REPOROOT%/bot
botrepo=`pwd`

cd $smvrepo/Source
echo ***cleaning $smvrepo/Source
git clean -dxf  >& $cleanlog

cd $smvrepo/Build
echo ***cleaning $smvrepo/Build
git clean -dxf  >& $cleanlog

cd $fdsrepo/Build
echo ***cleaning $fdsrepo/Build
git clean -dxf  >& $cleanlog 

cd $fdsrepo/Utilities
echo ***cleaning $fdsrepo/Utilities
echo.
git clean -dxf  >& $cleanlog

# build fds apps
BUILDUTIL fds2ascii intel_$platform
BUILDUTIL test_mpi  impi_intel_$platform
BUILDFDS

# build smokeview libraries and apps
BUILDLIB
BUILD     background
BUILD     smokediff
BUILD     pnginfo
BUILD     fds2fed
BUILD     smokezip
BUILD     $platformd2fds
BUILD     set_path
BUILD     sh2bat
BUILD     get_time
BUILDSMV

# verify fds apps were built
CHECK_BUILDUTIL    fds2ascii intel_$platform
CHECK_BUILDTESTMPI  
CHECK_BUILDFDS
CHECK_BUILDFDSOPENMP

# verify smokeview apps were built
CHECK_BUILD     background
CHECK_BUILD     smokediff
CHECK_BUILD     pnginfo
CHECK_BUILD     fds2fed
CHECK_BUILD     smokezip
CHECK_BUILD     $platformd2fds
CHECK_BUILD     set_path
CHECK_BUILD     sh2bat
CHECK_BUILD     get_time
CHECK_BUILDSMV

echo.
echo ***build complete
echo.

cd $CURDIR
