#!/bin/bash
curdir=`pwd`
BUILDING_nightly=$1

#*** determine platform script is running on

platform=linux
platform2=lnx
comp=intel
if [ "`uname`" == "Darwin" ] ; then
  platform="osx"
  platform2="osx"
  comp=gnu
fi
RELEASE=
BUILDTYPE=-t
BUILDTYPE2=test

cd ../../..
reporoot=`pwd`
basereporoot=`basename $reporoot`

cd $reporoot/bot/Scripts
echo updating repos
./update_repos.sh -m

if [ "$BUILDING_release" != "" ]; then
  ERROR=
  if [ "$BUNDLE_SMV_REVISION" == "" ]; then
    echo ***error: environment variable BUNDLE_SMV_REVISION not defined
    ERROR=1
  fi
  if [ "$BUNDLE_SMV_TAG" == "" ]; then
    echo ***error: environment variable BUNDLE_SMV_TAG not defined
    ERROR=1
  fi
  if [ "$ERROR" != "" ]; then
    exit
  fi
fi

echo "*** get smv repo revision"
if [ "$BUILDING_release" == "" ]; then
  cd $reporoot/bot/Bundlebot/nightly/output
  outdir=`pwd`
  cd $reporoot/bot/Bundlebot/nightly
  ./get_hash_revisions.sh $outdir >& $outdir/stage1_hash
  smv_hash=`head -1 $outdir/SMV_HASH`
else
  cd $reporoot/bot/Bundlebot/release/output
  outdir=`pwd`
  smv_hash=$BUNDLE_SMV_REVISION
fi

cd $reporoot/bot/Bundlebot/nightly
./clone_repos.sh $smv_hash $RELEASE >& $outdir/stage2_clone

if [ "$BUILDING_release" == "" ]; then
  cd $reporoot/smv
  smv_revision=`git describe --abbrev=7 --dirty --long`
  GHOWNER=`whoami`
else
  git tag -a $BUNDLE_SMV_TAG -m "tag for smokeview release" >> $outdir/stage2_clone 2>&1
  smv_revision=$BUNDLE_SMV_TAG
  GHOWNER=firemodels
fi
if [ "$BUILDING_nightly" != "" ]; then
  GHOWNER=firemodels
fi
echo "***     smv_hash: $smv_hash"
echo "*** smv_revision: $smv_revision"

echo "*** building libraries"

# build libraries
cd $reporoot/smv/Build/LIBS/${comp}_${platform}_64
./make_LIBS.sh >& $outdir/stage3_LIBS

echo "*** building applications"

progs="background flush hashfile smokediff fds2fed smokezip wind2fds"

for prog in $progs; do 
  cd $reporoot/smv/Build/$prog/${comp}_${platform}_64
  echo "*** building $prog"
  ./make_${prog}.sh >& $outdir/stage4_$prog
done

echo "*** building smokeview"
cd $reporoot/smv/Build/smokeview/${comp}_${platform}_64
./make_smokeview.sh $BUILDTYPE >& $outdir/stage5_smokeview

echo "*** bundling smokeview"

$reporoot/bot/Bundlebot/nightly/assemble_smvbundle.sh $BUILDTYPE2 $smv_revision $basereporoot >& $outdir/stage6_bundle


echo "*** uploading smokeview bundle"

FILELIST=`gh release view SMOKEVIEW_TEST  -R github.com/$GHOWNER/test_bundles | grep SMV | grep -v FDS | grep $platform2 | awk '{print $2}'`
for file in $FILELIST ; do
  gh release delete-asset SMOKEVIEW_TEST $file -R github.com/$GHOWNER/test_bundles -y
done

uploaddir=.bundle/uploads
$reporoot/bot/Bundlebot/nightly/upload_smvbundle.sh $uploaddir ${smv_revision}_${platform2}.sh     $basereporoot/bot/Bundlebot/nightly --clobber
$reporoot/bot/Bundlebot/nightly/upload_smvbundle.sh $uploaddir ${smv_revision}_${platform2}.sha1   $basereporoot/bot/Bundlebot/nightly -clobber

echo "*** upload complete"

