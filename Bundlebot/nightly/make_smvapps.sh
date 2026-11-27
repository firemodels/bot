#!/bin/bash
BUNDLETYPE=$1


# -------------------------------------------------------------

BUILDSMVLIBS()
{
  cd $smvrepo/Build/LIBS/${BUNDLE_SMVCOMPILER}_$platform
  ./make_LIBS.sh bot >> $outputdir/compile_smvlibs.log 2>&1 
}

# -------------------------------------------------------------

BUILD()
{
  prog=$1

  cd $smvrepo/Build/$prog/${BUNDLE_SMVCOMPILER}_$platform
  ./make_${prog}.sh bot >> $outputdir/compile_$prog.log 2>&1
}

# -------------------------------------------------------------

CHECK_BUILD()
{
  prog=$1

  if [ ! -e $smvrepo/Build/$prog/${BUNDLE_SMVCOMPILER}_$platform/${prog}_$platform ]; then
    echo "***error: The program ${prog}_${platform} failed to build"
    echo "***error: The program ${prog}_${platform} failed to build"   >> $errorlog 2>&1
  else
    echo "*** ${prog} built"
    cp $smvrepo/Build/$prog/${BUNDLE_SMVCOMPILER}_$platform/${prog}_$platform $CURDIR/apps/$prog
  fi
}

#--------------------- start of script -------------------------------

platform=linux
export FDS_BUILD_TARGET=intel
if [ "`uname`" == "Darwin" ] ; then
  platform="osx"
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
echo "*** cleaning $smvrepo/Source"
git clean -dxf  >> $cleanlog 2>&1 

cd $smvrepo/Build
echo "*** cleaning $smvrepo/Build"
git clean -dxf  >> $cleanlog 2>&1

# build smokeview libraries
echo "*** building smokeview libraries"
BUILDSMVLIBS

BUILD smokeview &
pid_smokeview=$!

echo "*** building fds2fed"
BUILD fds2fed &
pid_fds2fed=$!

echo "*** building pnginfo"
BUILD pnginfo &
pid_pnginfo=$!

if [ -z "$BUNDLETYPE" ]; then
  echo "*** building smokediff"
  BUILD smokediff &
  pid_smokediff=$!
fi

if [ -z "$BUNDLETYPE" ]; then
  conversion_app=smokezip
else
  conversion_app=part2iso
fi
echo "*** building $conversion_app"
BUILD "$conversion_app" &
pid_conversion_app=$!

echo "*** building wind2fds"
BUILD wind2fds &
pid_wind2fds=$!


# verify smokeview apps were built

wait $pid_smokeview
CHECK_BUILD smokeview

wait $pid_fds2fed
CHECK_BUILD fds2fed

wait $pid_pnginfo
CHECK_BUILD pnginfo

if [ -z "$BUNDLETYPE" ]; then
  wait $pid_smokediff
  CHECK_BUILD smokediff
fi

wait $pid_conversion_app
CHECK_BUILD "$conversion_app"

wait $pid_wind2fds
CHECK_BUILD wind2fds

echo "*** smv apps built"

cd $CURDIR
