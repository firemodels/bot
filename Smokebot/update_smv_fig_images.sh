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

if [ ! -d  $REPO/fig ]; then
  echo "***error: $REPO/fig does not exist"
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

FIG_DIR=$REPO/fig/compare/smokebot/images

echo copying SMV user guide figures
cp $FDS_REPO/Manuals/SMV_User_Guide/SCRIPT_FIGURES/*.png $FIG_DIR/fig/user/.
echo $FDS_REVISION > $FIG_DIR/user/FDS_REVISION
echo $SMV_REVISION > $FIG_DIR/user/SMV_REVISION

echo copying SMV verificaiton guide figures
cp $FDS_REPO/Manuals/SMV_Verification_Guide/SCRIPT_FIGURES/*.png $FIG_DIR/verification/.
echo $FDS_REVISION > $FIG_DIR/verification/FDS_REVISION
echo $SMV_REVISION > $FIG_DIR/verification/SMV_REVISION

cd $FIG_DIR/user
rm -f *_100.png *_200.png *_300.png  *_010.png *_020.png *_005.png *_030.png
rm -f *_[1-3]0.png *_06.png *_09.png *_12.png

cd $FIG_DIR/verification
rm -f *_0000.png *_0300.png *_0600.png  *_0900.png *_1200.png *_1500.png 
rm -f *_00000.png *_00025.png *_00050.png  *_00075.png *_00100.png *_00125.png 
rm -f *_00150.png *_00175.png *_00200.png  *_00225.png *_00250.png *_00275.png 
rm -f *_00300.png *_00325.png
rm -f *_030.png *_60.png *_120.png
rm -f *_015.png *_045.png
rm -f *_050.png *_100.png
rm -f *_30.png
rm -f *_000.png *_010.png *_020.png
rm -f *t_060.png
rm -f *cell_00.png
rm -f *chop_00.png
rm -f *bound_00.png
rm -f *slice*_00.png
rm -f *outline_00.png
rm -f *points_00.png
rm -f *solid_00.png
rm -f *_01.png
rm -f *_i[1-3].png
rm -f *_l[1-3].png
rm -f *_v[1-3].png
rm -f *_y[1-3].png
rm -r *_0[0-6].png
rm -r *_cell[1-2].png
rm -r *_node[1-3].png

cd $CURDIR
