#!/bin/bash

# -------------------------------------------------------------

BUILDFDS()
{
  echo ***building fds
  echo ""                >& $compilelog 
  echo "***************" >& $compilelog 

  echo "***building fds_${mpitype}_${fdscompiler}_${platform}" >& $compilelog 
  cd $fdsrepo/Build/${mpitype}_${fdscompiler}_${platform}
  ./make_fds.sh bot >& $compilelog 

  echo "***building fds_${mpitype}_${fdscompiler}_${platform}_openmp"
  echo "***building fds_${mpitype}_${fdscompiler}_${platform}_openmp" >& $compilelog 
  cd $fdsrepo/Build/${mpitype}_${fdscompiler}_${platform}_openmp
  ./make_fds.sh bot >& $compilelog 
}

# -------------------------------------------------------------

CHECK_BUILDFDS()
{
  if [ ! -e $fdsrepo/Build/${mpitype}_${fdscompiler}_${platform}/fds_${mpitype}_${fdscompiler}_${platform} ]; then
    echo "***error: The program fds_${mpitype}_${fdscompiler}_${platform} failed to build"
    echo "***error: The program fds_${mpitype}_${fdscompiler}_${platform} failed to build"  >& $errorlog
  else
    cp $fdsrepo/Build/${mpitype}_${fdscompiler}_${platform}/fds_${mpitype}_${fdscompiler}_${platform} apps/.
  fi
  if [ ! -e $fdsrepo/Build/${mpitype}_${fdscompiler}_${platform}_openmp/fds_${mpitype}_${fdscompiler}_${platform}_openmp ]; then
    echo "***error: The program fds_${mpitype}_${fdscompiler}_${platform}_openmp failed to build"
    echo "***error: The program fds_${mpitype}_${fdscompiler}_${platform}_openmp failed to build"  >& $errorlog
  else
    cp   if [ ! -e $fdsrepo/Build/${mpitype}_${fdscompiler}_${platform}_openmp/fds_${mpitype}_${fdscompiler}_${platform}_openmp apps/.
  fi
}

# -------------------------------------------------------------

BUILDFDSUTIL()
{
  prog=$1
  builddir=$2

  echo "***building $prog"
  echo ""                  >& $compilelog 
  echo "***************"   >& $compilelog 
  echo "***building $prog" >& $compilelog 
  cd $fdsrepo/Utilities/$prog/$builddir
  ./make_${prog}.sh bot >& $compilelog 
}

# -------------------------------------------------------------

CHECK_BUILDFDSUTIL()
{
  prog=$1
  builddir=$2

  if [ ! -e $fdsrepo/Utilities/$prog/$builddir/$prog_$builddir ]; then
    echo "***error: The program $prog_$builddir failed to build
    echo "***error: The program $prog_$builddir failed to build  >& $errorlog
  else
    cp $fdsrepo/Utilities/$prog/$builddir/$prog_$builddir  apps/.
  fi
}

# -------------------------------------------------------------

CHECK_BUILDTESTMPI()
{
  if [ ! -e $fdsrepo/Utilities/test_mpi/${mpitype}_${fdscompiler}_$platform/test_mpi ]; then
    echo "***error: The program test_mpi failed to build"
    echo "***error: The program test_mpi failed to build"  >& $errorlog
  else
    cp $fdsrepo/Utilities/test_mpi/${mpitype}_${fdscompiler}_$platform/test_mpi  apps/.
  fi
}

# -------------------------------------------------------------

BUILDLIB()
{
  echo "***building smokeview libraries"
  echo ""                >& $compilelog 
  echo "***************" >& $compilelog 
  echo "***building smokeview libraries" >& $compilelog 

  cd $smvrepo/Build/LIBS/${smvcompiler}_$platform$SMVSIZE
  ./make_LIBSi.sh bot >& $compilelog 
}

# -------------------------------------------------------------

BUILD()
{
  prog=$1

  echo "***building $prog_$platform$SMVSIZE "
  echo ""                >& $compilelog 
  echo "***************" >& $compilelog 
  echo "***building $prog" >& $compilelog 
  cd $smvrepo/Build/$prog/${smvcompiler}_$platform$SMVSIZE
 ./$make_${prog}.sh bot >& $compilelog 
}

# -------------------------------------------------------------

CHECK_BUILD()
{
  prog=$1

  if [ ! -e $smvrepo/Build/$prog/${smvcompiler}_$platform$SMVSIZE/$prog_$platform$SMVSIZE ]; then
    echo "***error: The program $prog_${platform}$SMVSIZE failed to build"
    echo "***error: The program $prog_${platform}$SMVSIZE failed to build"  >& $errorlog
  else
    cp $smvrepo/Build/$prog/${smvcompiler}_$platform$SMVSIZE/$prog_$platform$SMVSIZE apps/.
  fi
}

platform=linux
fdscompiler=intel
smvcompiler=intel
mpitype=impi
if [ "`uname`" == "Darwin" ] ; then
  platform="osx"
  fdscompiler=intel
  smvcompiler=gnu
  mpitype=ompi
fi

SMVSIZE=_64
CURDIR=`pwd`

git clean -dxf  >& /dev/null

cleanlog=$CURDIR/output/clean.log
compilelog=$CURDIR/output/compile.log
errorlog=$CURDIR/output/error.log

echo > $cleanlog
echo > $compilelog
echo > $errorlog

cd ../../..
REPOROOT=`pwd`

cd $REPOROOT/smv
smvrepo=`pwd`

cd $REPOROOT/fds
fdsrepo=`pwd`

cd $REPOROOT/bot
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
echo 
git clean -dxf  >& $cleanlog

# build fds apps
BUILDFDSUTIL test_mpi  ${mpitype}_${fdscompiler}_$platform
BUILDFDSUTIL fds2ascii ${fdscompiler}_$platform
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
BUILD     smokeview

# verify fds apps were built
CHECK_BUILDFDSUTIL    fds2ascii ${fdscompiler}_$platform
CHECK_BUILDTESTMPI  
CHECK_BUILDFDS

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
CHECK_BUILD     smokeview

echo 
echo ***build complete
echo 

cd $CURDIR
