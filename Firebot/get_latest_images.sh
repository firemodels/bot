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
cd $CURDIR

FDS_IMAGE_DIR=$TOROOT/fds/Manuals/FDS_Summary/images

cp $ROOT/fds/Manuals/FDS_User_Guide/SCRIPT_FIGURES/*.png         $FDS_IMAGE_DIR/user/.
cp $ROOT/fds/Manuals/FDS_Verification_Guide/SCRIPT_FIGURES/*.png $FDS_IMAGE_DIR/verification/.
