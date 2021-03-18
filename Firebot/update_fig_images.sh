#!/bin/bash
FROM_ROOT=$1

CURDIR=`pwd`
cd ../..
TO_ROOT=`pwd`
cd $CURDIR

if [ "$FROM_ROOT" == "" ]; then
  FROM_ROOT=$TO_ROOT
fi

if [ ! -d  $FROM_ROOT/fds ]; then
  echo "***error: $FROM_ROOT/fds does not exist"
  exit
fi

if [ ! -d  $FROM_ROOT/smv ]; then
  echo "***error: $FROM_ROOT/smv does not exist"
  exit
fi

if [ ! -d  $TO_ROOT/fig ]; then
  echo "***error: $TO_ROOT/fig does not exist"
  exit
fi

echo getting fds repo revision
cd $FROM_ROOT/fds
FDS_REVISION=`git describe --dirty --long`

echo getting smv repo revision
cd $FROM_ROOT/smv
SMV_REVISION=`git describe --dirty --long`

FIG_DIR=$TO_ROOT/fig/compare/firebot/images

echo copying FDS user guide figures
cp $FROM_ROOT/fds/Manuals/FDS_User_Guide/SCRIPT_FIGURES/*.png $FIG_DIR/user/.
echo $FDS_REVISION > $FIG_DIR/user/FDS_REVISION
echo $SMV_REVISION > $FIG_DIR/user/SMV_REVISION

echo copying FDS verificaiton guide figures
cp $FROM_ROOT/fds/Manuals/FDS_Verification_Guide/SCRIPT_FIGURES/*.png $FIG_DIR/verification/.
echo $FDS_REVISION > $FIG_DIR/verification/FDS_REVISION
echo $SMV_REVISION > $FIG_DIR/verification/SMV_REVISION




