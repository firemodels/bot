#!/bin/bash
SMVDEBUG=$1


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
  DEBUG=$2

  cd $smvrepo/Build/$prog/${smvcompiler}_$platform
  ./make_${prog}$DEBUG.sh bot >> $outputdir/compile_$prog$DEBUG.log 2>&1
}

# -------------------------------------------------------------

CHECK_BUILD()
{
  prog=$1
  DEBUG=$2

  if [ ! -e $smvrepo/Build/$prog/${smvcompiler}_$platform/${prog}_$platform$DEBUG ]; then
    echo "***error: The program ${prog}_${platform}$DEBUG failed to build"
    echo "***error: The program ${prog}_${platform}$DEBUG failed to build"   >> $errorlog 2>&1
  else
    echo "*** ${prog}$DEBUG built"
    cp $smvrepo/Build/$prog/${smvcompiler}_$platform/${prog}_$platform$DEBUG $CURDIR/apps/$prog
  fi
}

#--------------------- start of script -------------------------------

platform=linux
smvcompiler=intel
export FDS_BUILD_TARGET=intel
if [ "`uname`" == "Darwin" ] ; then
  platform="osx"
  export FDS_BUILD_TARGET=osx
  smvcompiler=gnu
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
echo "*** cleaning $smvrepo/Source"
git clean -dxf  >> $cleanlog 2>&1 

cd $smvrepo/Build
echo "*** cleaning $smvrepo/Build"
git clean -dxf  >> $cleanlog 2>&1

# build smokeview libraries
echo "*** building smokeview libraries"
BUILDSMVLIBS

BUILD smokeview $SMVDEBUG &
pid_smokeview=$!

echo "*** building background"
BUILD background &
pid_background=$!

echo "*** building fds2fed"
BUILD fds2fed &
pid_fds2fed=$!

echo "*** building flush"
BUILD flush &
pid_flush=$!

echo "*** building pnginfo"
BUILD pnginfo &
pid_pnginfo=$!

echo "*** building smokediff"
BUILD smokediff &
pid_smokediff=$!

echo "*** building smokezip"
BUILD smokezip &
pid_smokezip=$!

echo "*** building wind2fds"
BUILD wind2fds &
pid_wind2fds=$!


# verify smokeview apps were built

wait $pid_smokeview
CHECK_BUILD smokeview $SMVDEBUG

wait $pid_background
CHECK_BUILD background

wait $pid_fds2fed
CHECK_BUILD fds2fed

wait $pid_flush
CHECK_BUILD flush

wait $pid_pnginfo
CHECK_BUILD pnginfo

wait $pid_smokediff
CHECK_BUILD smokediff

wait $pid_smokezip
CHECK_BUILD smokezip

wait $pid_wind2fds
CHECK_BUILD wind2fds

echo "*** smv apps built"

cd $CURDIR
