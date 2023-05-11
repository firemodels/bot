#!/bin/bash
platform=linux
platform2=lnx
if [ "`uname`" == "Darwin" ] ; then
  platform="osx"
  platform2="osx"
fi


curdir=`pwd`
cd ../../../..
reporoot=`pwd`
basereporoot=`basename $reporoot`
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
cd $reporoot/smv
smv_revision=`git describe --abbrev=7 --dirty --long`

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

echo
echo -----------------------------------------------------------------------------
echo ---------------------- Building Smokeview bundle -----------------------------------------
echo -----------------------------------------------------------------------------
echo

$reporoot/bot/Bundlebot/smv/scripts/make_bundle.sh test $smv_revision $basereporoot


echo
echo -----------------------------------------------------------------------------
echo ---------------------- Uploading Smokeview bundle -----------------------------------------
echo -----------------------------------------------------------------------------
echo

uploaddir=.bundle/uploads
$reporoot/bot/Bundlebot/scripts/upload_smvbundle.sh $uploaddir ${smv_revision}_${platform2}.sh     $basereporoot/bot/Bundlebot/scripts $GH_SMOKEVIEW_TAG $GH_OWNER $GH_REPO --clobber
$reporoot/bot/Bundlebot/scripts/upload_smvbundle.sh $uploaddir ${smv_revision}_${platform2}.sha1   $basereporoot/bot/Bundlebot/scripts $GH_SMOKEVIEW_TAG $GH_OWNER $GH_REPO --clobber

echo upload complete

