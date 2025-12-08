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

BUILDFDSLIB()
{
  FDSLIB=$1
  cdir=`pwd`
  source ./build_fdslib.sh $FDSLIB >> $outputdir/compile_$FDSLIB.log 2>&1
  cd $cdir
}

#--------------------- start of script -------------------------------

platform=linux
fdscompiler=intel
smvcompiler=intel
mpitype=impi
export FDS_BUILD_TARGET=intel
if [ "`uname`" == "Darwin" ] ; then
  platform="osx"
  fdscompiler=intel
  smvcompiler=gnu
  mpitype=ompi
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

cd $fdsrepo/Build
echo ***cleaning $fdsrepo/Build
git clean -dxf  >> $cleanlog 2>&1 

cd $CURDIR
# build hypre library
echo building hypre
BUILDFDSLIB hypre &
pid_hypre=$!

echo building sundials
BUILDFDSLIB sundials &
pid_sundials=$!

wait $pid_hypre
echo hypre built

wait $pid_sundials
echo sundials built

# build fds apps
echo building fds
BUILDFDS                                                      &
pid_fds=$!

echo building fds openmp
BUILDFDSOPENMP                                                &
pid_fdsopenmp=$!

wait $pid_fds
echo fds built
CHECK_BUILDFDS

wait $pid_fdsopenmp
echo fds_openmp built
CHECK_BUILDFDSOPENMP

echo
echo ***fds app builds complete
echo

cd $CURDIR
