#!/bin/bash


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
    echo ${prog} built
    cp $smvrepo/Build/$prog/${smvcompiler}_$platform/${prog}_$platform $CURDIR/apps/$prog
  fi
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
cleanlog=$CURDIR/output/smvclean.log
errorlog=$CURDIR/output/smverror.log

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

# build smokeview libraries
echo building smokeview libraries
BUILDSMVLIBS &
pid_smvlibs=$!

echo building background
BUILD background &
pid_background=$!

echo building flush
BUILD flush &
pid_flush=$!

echo building fds2fed
BUILD fds2fed &
pid_fds2fed=$!

echo building smokediff
BUILD smokediff &
pid_smokediff=$!

echo building wind2fds
BUILD wind2fds &
pid_wind2fds=$!

#wait for smokeview libraries to be built before continuing
wait $pid_smvlibs

echo building pnginfo
BUILD pnginfo &
pid_pnginfo=$!

echo building smokeview
BUILD smokeview &
pid_smokeview=$!

echo building smokezip
BUILD smokezip &
pid_smokezip=$!

# verify smokeview apps were built

wait $pid_background
CHECK_BUILD background

wait $pid_flush
CHECK_BUILD flush

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

echo smv app builds complete

cd $CURDIR
