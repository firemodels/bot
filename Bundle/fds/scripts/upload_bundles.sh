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
  platform=$1
  if [ "$platform" == "win64" ]; then
    ext=.exe
  else
    ext=.sh
  fi

  file=${BUNDLE_BASE}_$platform$ext
  shafile=${BUNDLE_BASE}_${platform}.sha1

  upload=1
  if [ ! -e $BUNDLE_DIR/$file ]; then
    echo "file doesn't exist"
    upload=
  fi
  if [ ! -e $BUNDLE_DIR/$shafile ]; then
    echo "shafile doesn't exist"
    upload=
  fi
  if [ "$upload" == "1" ]; then
    $GDRIVE list  | grep $platform | awk '{ system("~/bin/gdrive delete -i " $1)} '
    $GDRIVE upload -p $BUNDLE_PARENT_ID -f $BUNDLE_DIR/$file
    nfiles=`$GDRIVE list  | grep $file | wc -l`
    if [ $nfiles -eq 0 ]; then
      echo "*** warning: The bundle file $file failed to upload to google drive"
    fi
    $GDRIVE upload -p $BUNDLE_PARENT_ID -f $BUNDLE_DIR/$shafile
    nfiles=`$GDRIVE list  | grep $shafile | wc -l`
    if [ $nfiles -eq 0 ]; then
      echo "*** warning: The sha1 file $sha1file failed to upload to google drive"
    fi
  else
    if [ ! -e $BUNDLE_DIR/$file ]; then
      echo "*** warning: The bundle file $BUNDLE_DIR/$file  does not exist"
    fi
    if [ ! -e $BUNDLE_DIR/$shafile ]; then
      echo "*** warning: The sha1 file $BUNDLE_DIR/$shafile  does not exist"
    fi
  fi
}

if [ -e $GDRIVE ] ; then
  UPLOAD_BUNDLE linux64
#  UPLOAD_BUNDLE osx64
#  UPLOAD_BUNDLE win64
fi
