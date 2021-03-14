#!/bin/bash
REPO=$1

CURDIR=`pwd`
if [ "$REPO" == "" ]; then
  cd ../..
  REPO=`pwd`
  cd $CURDIR
fi

if [ ! -d  $REPO/fds ]; then
  echo "***error: $REPO/fds does not exist"
  exit
fi

if [ ! -d  $REPO/smv ]; then
  echo "***error: $REPO/smv does not exist"
  exit
fi

cd $CURDIR/../..
TOREPO=`pwd`
cd $CURDIR
FIG_DIR=$TOREPO/fig/compare/smokebot/images
if [ ! -d  $TOREPO/fig ]; then
  echo "***error: $TOREPO/fig does not exist"
  exit
fi

echo getting fds repo revision
cd $REPO/fds
FDS_REPO=`pwd`
FDS_REVISION=`git describe --dirty --long`

echo getting smv repo revision
cd $REPO/smv
SMV_REPO=`pwd`
SMV_REVISION=`git describe --dirty --long`

echo copying SMV user guide figures
cp $REPO/smv/Manuals/SMV_User_Guide/SCRIPT_FIGURES/*.png $FIG_DIR/user/.
echo $FDS_REVISION > $FIG_DIR/user/FDS_REVISION
echo $SMV_REVISION > $FIG_DIR/user/SMV_REVISION

echo copying SMV verificaiton guide figures
cp $REPO/smv/Manuals/SMV_Verification_Guide/SCRIPT_FIGURES/*.png $FIG_DIR/verification/.
echo $FDS_REVISION > $FIG_DIR/verification/FDS_REVISION
echo $SMV_REVISION > $FIG_DIR/verification/SMV_REVISION

cd $CURDIR
./remove_images.sh $FIG_DIR
