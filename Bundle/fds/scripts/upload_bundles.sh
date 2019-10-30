#!/bin/bash
BUNDLE_DIR=$1
BUNDLE_BASE=$2

GDRIVE=~/bin/gdrive
# directory containing nightly bundles on google drive : nightly_bundles
#  the following string is gound at the end of the URL of the nightly_bundles
#  directory on Google Drive
BUNDLE_PARENT_ID=1X-gRYGPGtcewgnNiNBuho3U8zDFVqFsC

UPLOAD_BUNDLE ()
{
  ext=$1

  file=${BUNDLE_BASE}_$ext
  if [ -e $BUNDLE_DIR/$file ]; then
    $GDRIVE list  | grep $ext | awk '{ system("~/bin/gdrive delete -i " $1)} '
    $GDRIVE upload -p $BUNDLE_PARENT_ID -f $BUNDLE_DIR/$file
    nfiles=`$GDRIVE list  | grep $file | wc -l`
    if [ $nfiles -eq 0 ]; then
      echo "*** warning: The bundle file $file failed to upload to google drive"
    fi
  else
    echo "*** warning: The bundle file $BUNDLE_DIR/$file  does not exist"
  fi
}

if [ -e $GDRIVE ] ; then
  UPLOAD_BUNDLE linux64.sh
  UPLOAD_BUNDLE osx64.sh
  UPLOAD_BUNDLE win64.exe
fi
