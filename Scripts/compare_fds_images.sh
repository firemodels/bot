#!/bin/bash

fromfdsrepo=~firebot/FireModels_clone/fds

CURDIR=`pwd`
fdsrepo=../../fds
cd $fdsrepo
fdsrepo=`pwd`
cd $CURDIR

figrepo=../../fig
cd $figrepo
figrepo=`pwd`
cd $CURDIR

botrepo=../../bot
cd $botrepo
botrepo=`pwd`
cd $CURDIR

OUTPUT_DIR=$botrepo/Firebot/output
FDS_SUMMARY_DIR=$fdsrepo/Manuals/FDS_Summary

if [ -d $FDS_SUMMARY_DIR ]; then
  cp $fromfdsrepo/Manuals/FDS_User_Guide/SCRIPT_FIGURES/*.png         $FDS_SUMMARY_DIR/images/user/.
  cp $fromfdsrepo/Manuals/FDS_Verification_Guide/SCRIPT_FIGURES/*.png $FDS_SUMMARY_DIR/images/verification/.
  DATE=`date +"%b %d, %Y - %r"`

# compare images

  cd $botrepo/Firebot
  ./compare_images.sh $figrepo/fds/Reference_Figures $FDS_SUMMARY_DIR/images $FDS_SUMMARY_DIR/diffs/images |& tee $OUTPUT_DIR/image_compare

# look for fyis
  if [[ `grep '***fyi:' $OUTPUT_DIR/image_compare` == "" ]]
  then
    # Continue along
    :
  else
    echo "Image comparison FYIs:"
    grep '***fyi:' $OUTPUT_DIR/image_compare
  fi

# look for warnings
  if [[ `grep '***warning:' $OUTPUT_DIR/image_compare` == "" ]]
  then
    # Continue along
    :
  else
    echo "Image comparison Warnings:"
    grep '***warning:' $OUTPUT_DIR/image_compare
  fi
else
  echo "***error: The directory $FDS_SUMMARY_DIR does not exist"
fi

