#!/bin/bash
ROOT=$1

CURDIR=`pwd`
if [ "$ROOT" == "" ]; then
  ROOT=../..
fi
cd $ROOT
ROOT=`pwd`


cd $CURDIR/../..
TOROOT=`pwd`
SMV_IMAGE_DIR=$TOROOT/smv/Manuals/SMV_Summary/images
cd $CURDIR

cp $ROOT/smv/Manuals/SMV_User_Guide/SCRIPT_FIGURES/*.png         $SMV_IMAGE_DIR/user/.
cp $ROOT/smv/Manuals/SMV_Verification_Guide/SCRIPT_FIGURES/*.png $SMV_IMAGE_DIR/verification/.

cd $CURDIR
./remove_images.sh $SMV_IMAGE_DIR
