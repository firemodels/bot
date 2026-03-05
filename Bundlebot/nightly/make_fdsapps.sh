#!/bin/bash
MPITYPE=$1

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
    echo "***error: The program ${prog}_$builddir failed to build"
    echo "***error: The program ${prog}_$builddir failed to build"   >> $errorlog 2>&1
  else
    echo "*** ${prog}_$builddir built"
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
    echo "*** test_mpi built"
    cp $fdsrepo/Utilities/test_mpi/${mpitype}_${fdscompiler}_$platform/test_mpi  $CURDIR/apps/test_mpi
  fi
}
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
    echo "*** fds_${mpitype}_${fdscompiler}_${platform} built"
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
    echo "*** fds_${mpitype}_${fdscompiler}_${platform}_openmp built"
    cp  $fdsrepo/Build/${mpitype}_${fdscompiler}_${platform}_openmp/fds_${mpitype}_${fdscompiler}_${platform}_openmp $CURDIR/apps/fds_openmp
  fi
}

# -------------------------------------------------------------

BUILDFDSLIB()
{
  FDSLIB=$1
  cdir=`pwd`
  source ./build_fdslib.sh $FDSLIB >> $outputdir/compile_$FDSLIB.log 2>&1
  cd $cdir
}

#--------------------- start of script -------------------------------

if [ "$MPITYPE" == "INTELMPI" ]; then
  mpitype=impi
  fdscompiler=intel
else
  mpitype=ompi
  fdscompiler=gnu
fi
export FDS_BUILD_TARGET=intel
platform=linux
if [ "`uname`" == "Darwin" ] ; then
  platform="osx"
  export FDS_BUILD_TARGET=osx
fi

CURDIR=`pwd`

outputdir=$CURDIR/output
cleanlog=$CURDIR/output/fdsclean.log
errorlog=$CURDIR/output/fdserror.log

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

cd $fdsrepo/Utilities
echo "*** cleaning $fdsrepo/Utilities"
git clean -dxf  >> $cleanlog 2>&1 

cd $fdsrepo/Build
echo "*** cleaning $fdsrepo/Build"
git clean -dxf  >> $cleanlog 2>&1 

cd $CURDIR

echo "*** building test_mpi"
BUILDFDSUTIL test_mpi  ${mpitype}_${fdscompiler}_$platform    &
pid_test_mpi=$!

echo "*** building fds2ascii"
BUILDFDSUTIL fds2ascii ${fdscompiler}_$platform               &
pid_fds2ascii=$!

# build hypre library
echo "*** building hypre"
BUILDFDSLIB hypre &
pid_hypre=$!

echo "*** building sundials"
BUILDFDSLIB sundials &
pid_sundials=$!

wait $pid_hypre
echo "*** hypre built"

wait $pid_sundials
echo "*** sundials built"

# build fds apps
echo "*** building fds"
BUILDFDS                                                      &
pid_fds=$!

if [ "$MPITYPE" == "INTELMPI" ]; then
  echo "*** building fds openmp"
  BUILDFDSOPENMP                                                &
  pid_fdsopenmp=$!
fi

wait $pid_fds
CHECK_BUILDFDS


if [ "$MPITYPE" == "INTELMPI" ]; then
  wait $pid_fdsopenmp
  CHECK_BUILDFDSOPENMP
fi

wait $pid_fds2ascii
CHECK_BUILDFDSUTIL    fds2ascii ${fdscompiler}_$platform

wait $pid_test_mpi
CHECK_BUILDTESTMPI  

cd $CURDIR
