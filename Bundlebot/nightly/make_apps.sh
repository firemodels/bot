#!/bin/bash

# -------------------------------------------------------------

BUILDFDS()
{
  cd $fdsrepo/Build/${mpitype}_${fdscompiler}_${platform}
  ./make_fds.sh bot  >> $outputdir/compile_fds.log 2>&1
}

BUILDFDSOPENMP()
{
  cd $fdsrepo/Build/${mpitype}_${fdscompiler}_${platform}_openmp
  cp make_fds.sh make_fds_openmp.sh
  ./make_fds_openmp.sh bot >> $outputdir/compile_fdsopenmp.log 2>&1
}

# -------------------------------------------------------------

CHECK_BUILDFDS()
{
  if [ ! -e $fdsrepo/Build/${mpitype}_${fdscompiler}_${platform}/fds_${mpitype}_${fdscompiler}_${platform} ]; then
    echo "***error: The program fds_${mpitype}_${fdscompiler}_${platform} failed to build"
    echo "***error: The program fds_${mpitype}_${fdscompiler}_${platform} failed to build"  >> $errorlog 2>&1
  else
    echo $fdsrepo/Build/${mpitype}_${fdscompiler}_${platform}/fds_${mpitype}_${fdscompiler}_${platform} built
    cp $fdsrepo/Build/${mpitype}_${fdscompiler}_${platform}/fds_${mpitype}_${fdscompiler}_${platform} $CURDIR/apps/fds
  fi
}

# -------------------------------------------------------------

CHECK_BUILDFDSOPENMP()
{
  if [ ! -e $fdsrepo/Build/${mpitype}_${fdscompiler}_${platform}_openmp/fds_${mpitype}_${fdscompiler}_${platform}_openmp ]; then
    echo "***error: The program fds_${mpitype}_${fdscompiler}_${platform}_openmp failed to build"
    echo "***error: The program fds_${mpitype}_${fdscompiler}_${platform}_openmp failed to build"   >> $errorlog 2>&1
  else
    echo $fdsrepo/Build/${mpitype}_${fdscompiler}_${platform}_openmp/fds_${mpitype}_${fdscompiler}_${platform}_openmp built
    cp  $fdsrepo/Build/${mpitype}_${fdscompiler}_${platform}_openmp/fds_${mpitype}_${fdscompiler}_${platform}_openmp $CURDIR/apps/fds_openmp
  fi
}

# -------------------------------------------------------------

BUILDFDSUTIL()
{
  prog=$1
  builddir=$2

  cd $fdsrepo/Utilities/$prog/$builddir
  ./make_${prog}.sh bot >> $outputdir/compile_$prog.log 2>&1
}

# -------------------------------------------------------------

CHECK_BUILDFDSUTIL()
{
  prog=$1
  builddir=$2

  if [ ! -e $fdsrepo/Utilities/$prog/$builddir/${prog}_$builddir ]; then
    echo "***error: The program ${prog}_$builddir failed to build
    echo "***error: The program ${prog}_$builddir failed to build   >> $errorlog 2>&1
  else
    echo $fdsrepo/Utilities/$prog/$builddir/${prog}_$builddir built
    cp $fdsrepo/Utilities/$prog/$builddir/${prog}_$builddir  $CURDIR/apps/$prog
  fi
}

# -------------------------------------------------------------

CHECK_BUILDTESTMPI()
{
  if [ ! -e $fdsrepo/Utilities/test_mpi/${mpitype}_${fdscompiler}_$platform/test_mpi ]; then
    echo "***error: The program test_mpi failed to build"
    echo "***error: The program test_mpi failed to build"  >> $errorlog 2>&1
  else
    echo $fdsrepo/Utilities/test_mpi/${mpitype}_${fdscompiler}_$platform/test_mpi built
    cp $fdsrepo/Utilities/test_mpi/${mpitype}_${fdscompiler}_$platform/test_mpi  $CURDIR/apps/test_mpi
  fi
}

# -------------------------------------------------------------

BUILDHYPRE()
{
  source $fdsrepo/Build/Scripts/HYPRE/build_hypre.sh confmake.sh true >> $outputdir/compile_hypre.log 2>&1
}

# -------------------------------------------------------------

BUILDSUNDIALS()
{
  source $fdsrepo/Build/Scripts/SUNDIALS/build_sundials.sh confmake.sh true >> $outputdir/compile_sundials.log 2>&1
}

# -------------------------------------------------------------

BUILDSMVLIBS()
{
  cd $smvrepo/Build/LIBS/${smvcompiler}_$platform
  ./make_LIBS.sh bot >> $outputdir/compile_smvlibs.log 2>&1 
}

# -------------------------------------------------------------

BUILD()
{
  prog=$1

  cd $smvrepo/Build/$prog/${smvcompiler}_$platform
  ./make_${prog}.sh bot >> $outputdir/compile_$prog.log 2>&1
}

# -------------------------------------------------------------

CHECK_BUILD()
{
  prog=$1

  if [ ! -e $smvrepo/Build/$prog/${smvcompiler}_$platform/${prog}_$platform ]; then
    echo "***error: The program ${prog}_${platform} failed to build"
    echo "***error: The program ${prog}_${platform} failed to build"   >> $errorlog 2>&1
  else
    echo $smvrepo/Build/$prog/${smvcompiler}_$platform/${prog}_$platform built
    cp $smvrepo/Build/$prog/${smvcompiler}_$platform/${prog}_$platform $CURDIR/apps/$prog
  fi
}

#--------------------- start of script -------------------------------

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

CURDIR=`pwd`

echo ***cleaning $CURDIR
git clean -dxf  >& /dev/null

outputdir=$CURDIR/output
cleanlog=$CURDIR/output/clean.log
errorlog=$CURDIR/output/error.log

echo > $cleanlog
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
git clean -dxf  >> $cleanlog 2>&1 

cd $smvrepo/Build
echo ***cleaning $smvrepo/Build
git clean -dxf  >> $cleanlog 2>&1

cd $fdsrepo/Build
echo ***cleaning $fdsrepo/Build
git clean -dxf  >> $cleanlog 2>&1 

cd $fdsrepo/Utilities
echo ***cleaning $fdsrepo/Utilities
echo 
git clean -dxf  >> $cleanlog 2>&1

# build hypre librarie
echo building hypre library
BUILDHYPRE &
pid_hypre=$!

# build sundials library
echo building sundials library
BUILDSUNDIALS &
pid_sundials=$!

echo building test_mpi
BUILDFDSUTIL test_mpi  ${mpitype}_${fdscompiler}_$platform    &
pid_test_mpi=$!

echo building fds2ascii
BUILDFDSUTIL fds2ascii ${fdscompiler}_$platform               &
pid_fds2ascii=$!

# build smokeview libraries and apps
echo building smokeview libraries
BUILDSMVLIBS &
pid_smvlibs=$!

wait $pid_hypre
wait $pid_sundials
# build fds apps
echo building fds
BUILDFDS                                                      &
pid_fds=$!

echo building fds openmp
BUILDFDSOPENMP                                                &
pid_fdsopenmp=$!

#wait for smokeview libraries to be built before continuing
wait $pid_smvlibs

echo building background
BUILD background &
pid_background=$!

echo building fds2fed
BUILD fds2fed &
pid_fds2fed=$!

echo building pnginfo
BUILD pnginfo &
pid_pnginfo=$!

echo building smokediff
BUILD smokediff &
pid_smokediff=$!

echo building smokeview
BUILD smokeview &
pid_smokeview=$!

echo building smokezip
BUILD smokezip &
pid_smokezip=$!

echo building wind2fds
BUILD wind2fds &
pid_wind2fds=$!

# verify smokeview apps were built

wait $pid_background
CHECK_BUILD background

wait $pid_fds2fed
CHECK_BUILD fds2fed

wait $pid_pnginfo
CHECK_BUILD pnginfo

wait $pid_smokediff
CHECK_BUILD smokediff

wait $pid_smokeview
CHECK_BUILD smokeview

wait $pid_smokezip
CHECK_BUILD smokezip

wait $pid_wind2fds
CHECK_BUILD wind2fds

# verify fds apps were built

wait $pid_fds2ascii
CHECK_BUILDFDSUTIL    fds2ascii ${fdscompiler}_$platform

wait $pid_test_mpi
CHECK_BUILDTESTMPI  

wait $pid_fds
CHECK_BUILDFDS

wait $pid_fdsopenmp
CHECK_BUILDFDSOPENMP

echo 
echo ***build complete
echo 

cd $CURDIR
