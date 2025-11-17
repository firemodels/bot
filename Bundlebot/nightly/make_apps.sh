#!/bin/bash

# -------------------------------------------------------------

BUILDFDS()
{
  echo ***building fds
  echo ""                >> $compilelog 2>&1 
  echo "***************" >> $compilelog 2>&1 

  echo "***building fds_${mpitype}_${fdscompiler}_${platform}" >> $compilelog 2>&1 
  cd $fdsrepo/Build/${mpitype}_${fdscompiler}_${platform}
  ( $RUNSCRIPT ./make_fds.sh bot  >> $compilelog 2>&1 ) &

  echo "***building fds_${mpitype}_${fdscompiler}_${platform}_openmp"
  echo "***building fds_${mpitype}_${fdscompiler}_${platform}_openmp" >> $compilelog 2>&1 
  cd $fdsrepo/Build/${mpitype}_${fdscompiler}_${platform}_openmp
  cp make_fds.sh make_fds_openmp.sh
  ( $RUNSCRIPT ./make_fds_openmp.sh bot >> $compilelog 2>&1  ) &
}

# -------------------------------------------------------------

CHECK_BUILDFDS()
{
  $WAITSCRIPT ./make_fds.sh
  if [ ! -e $fdsrepo/Build/${mpitype}_${fdscompiler}_${platform}/fds_${mpitype}_${fdscompiler}_${platform} ]; then
    echo "***error: The program fds_${mpitype}_${fdscompiler}_${platform} failed to build"
    echo "***error: The program fds_${mpitype}_${fdscompiler}_${platform} failed to build"  >> $errorlog 2>&1
  else
    cp $fdsrepo/Build/${mpitype}_${fdscompiler}_${platform}/fds_${mpitype}_${fdscompiler}_${platform} $CURDIR/apps/.
  fi
  $WAITSCRIPT ./make_fds_openmp.sh
  if [ ! -e $fdsrepo/Build/${mpitype}_${fdscompiler}_${platform}_openmp/fds_${mpitype}_${fdscompiler}_${platform}_openmp ]; then
    echo "***error: The program fds_${mpitype}_${fdscompiler}_${platform}_openmp failed to build"
    echo "***error: The program fds_${mpitype}_${fdscompiler}_${platform}_openmp failed to build"   >> $errorlog 2>&1
  else
    cp  $fdsrepo/Build/${mpitype}_${fdscompiler}_${platform}_openmp/fds_${mpitype}_${fdscompiler}_${platform}_openmp $CURDIR/apps/.
  fi
}

# -------------------------------------------------------------

BUILDFDSUTIL()
{
  prog=$1
  builddir=$2

  echo "***building $prog"
  echo ""                  >> $compilelog 2>&1 
  echo "***************"   >> $compilelog 2>&1 
  echo "***building $prog" >> $compilelog 2>&1 
  cd $fdsrepo/Utilities/$prog/$builddir
  ( $RUNSCRIPT ./make_${prog}.sh bot >> $compilelog 2>&1 ) &
}

# -------------------------------------------------------------

CHECK_BUILDFDSUTIL()
{
  prog=$1
  builddir=$2

  $WAITSCRIPT ./make_${prog}.sh
  if [ ! -e $fdsrepo/Utilities/$prog/$builddir/${prog}_$builddir ]; then
    echo "***error: The program ${prog}_$builddir failed to build
    echo "***error: The program ${prog}_$builddir failed to build   >> $errorlog 2>&1
  else
    cp $fdsrepo/Utilities/$prog/$builddir/${prog}_$builddir  $CURDIR/apps/.
  fi
}

# -------------------------------------------------------------

CHECK_BUILDTESTMPI()
{
  $WAITSCRIPT ./make_test_mpi.sh
  if [ ! -e $fdsrepo/Utilities/test_mpi/${mpitype}_${fdscompiler}_$platform/test_mpi ]; then
    echo "***error: The program test_mpi failed to build"
    echo "***error: The program test_mpi failed to build"  >> $errorlog 2>&1
  else
    cp $fdsrepo/Utilities/test_mpi/${mpitype}_${fdscompiler}_$platform/test_mpi  $CURDIR/apps/.
  fi
}

# -------------------------------------------------------------

BUILDLIBS()
{
  echo "***building smokeview libraries"
  echo ""                >> $compilelog 2>&1 
  echo "***************" >> $compilelog 2>&1 
  echo "***building smokeview libraries" >> $compilelog 2>&1 

  cd $smvrepo/Build/LIBS/${smvcompiler}_$platform$SMVSIZE
  ./make_LIBS.sh bot >> $compilelog 2>&1 
}

# -------------------------------------------------------------

BUILD()
{
  prog=$1

  echo "***building ${prog}_$platform$SMVSIZE "
  echo ""                >> $compilelog 2>&1 
  echo "***************" >> $compilelog 2>&1 
  echo "***building $prog" >> $compilelog 2>&1 
  cd $smvrepo/Build/$prog/${smvcompiler}_$platform$SMVSIZE
 ( $RUNSCRIPT ./make_${prog}.sh bot >> $compilelog 2>&1  ) &
}

# -------------------------------------------------------------

CHECK_BUILD()
{
  prog=$1

  $WAITSCRIPT ./make_${prog}.sh
  if [ ! -e $smvrepo/Build/$prog/${smvcompiler}_$platform$SMVSIZE/${prog}_$platform$SMVSIZE ]; then
    echo "***error: The program ${prog}_${platform}$SMVSIZE failed to build"
    echo "***error: The program ${prog}_${platform}$SMVSIZE failed to build"   >> $errorlog 2>&1
  else
    cp $smvrepo/Build/$prog/${smvcompiler}_$platform$SMVSIZE/${prog}_$platform$SMVSIZE $CURDIR/apps/.
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

SMVSIZE=_64
CURDIR=`pwd`

RUNSCRIPT=$CURDIR/run_script.sh
WAITSCRIPT=$CURDIR/wait_script.sh

echo ***cleaning $CURDIR
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

# build fds apps
BUILDFDSUTIL test_mpi  ${mpitype}_${fdscompiler}_$platform
BUILDFDSUTIL fds2ascii ${fdscompiler}_$platform
BUILDFDS

# build smokeview libraries and apps
BUILDLIBS
BUILD     background
BUILD     fds2fed
BUILD     pnginfo
BUILD     smokediff
BUILD     smokeview
BUILD     smokezip
BUILD     wind2fds

# verify smokeview apps were built
CHECK_BUILD     background
CHECK_BUILD     fds2fed
CHECK_BUILD     pnginfo
CHECK_BUILD     smokediff
CHECK_BUILD     smokeview
CHECK_BUILD     smokezip
CHECK_BUILD     wind2fds

# verify fds apps were built
CHECK_BUILDFDSUTIL    fds2ascii ${fdscompiler}_$platform
CHECK_BUILDTESTMPI  
CHECK_BUILDFDS

echo 
echo ***build complete
echo 

cd $CURDIR
