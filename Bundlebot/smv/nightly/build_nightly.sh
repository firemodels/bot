#!/bin/bash
platform=linux

# batch file for creating libraries on windows, linux or osx

curdir=`pwd`
cd ../../../..
reporoot=`pwd`
cd $curdir

echo -----------------------------------------------------------------------------
echo ---------------------- get smv repo revision --------------------------------
echo -----------------------------------------------------------------------------

./get_hash_revisions.sh
smv_hash=`head -1 output/SMV_HASH`

echo -----------------------------------------------------------------------------
echo ---------------------- get clone smv repo ---------------------------------
echo -----------------------------------------------------------------------------

./clone_repos.sh $smv_hash

# build libraries
echo building libraries
cd $reporoot/smv/Build/LIBS/intel_${platform}_64
./make_LIBS.sh

echo.
echo  Building applications

progs="background flush hashfile smokediff smokezip wind2fds"

for prog in $progs; do 
  cd $reporoot/smv/Build/$prog/intel_${platform}_64
  echo
  echo -----------------------------------------------------------------------------
  echo ---------------------- building $prog -----------------------------------------
  echo -----------------------------------------------------------------------------
  ./make_${prog}.sh
done

echo.
echo -----------------------------------------------------------------------------
echo ---------------------- building smokeview -----------------------------------------
echo -----------------------------------------------------------------------------
cd $reporoot/smv/Build/smokeview/intel_${platform}_64
./make_smokeview.sh
exit

echo
echo -----------------------------------------------------------------------------
echo ---------------------- Building Smokeview bundle -----------------------------------------
echo -----------------------------------------------------------------------------
echo

%reporoot%/bot/Bundlebot/smv/scripts/make_testbundle

echo
echo -----------------------------------------------------------------------------
echo ---------------------- Uploading Smokeview bundle -----------------------------------------
echo -----------------------------------------------------------------------------
echo

uploaddir=$HOME/.bundle/uploads


echo.
echo upload complete

cd %curdir%
