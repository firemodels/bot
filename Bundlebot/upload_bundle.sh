#!/bin/bash
BUNDLE_DIR=$1
BUNDLE_BASE=$2
NIGHTLY=$3
platform=$4

if [ "$NIGHTLY" == "null" ]; then
  NIGHTLY=
else
  NIGHTLY=${NIGHTLY}_
fi

scriptdir=`dirname "$(readlink -f "$0")"`
cd $scriptdir

erase=1
erase_local=

GDRIVE=~/bin/gdrive
# directory containing nightly bundles on google drive : nightly_bundles
#  the following string is gound at the end of the URL of the nightly_bundles
#  directory on Google Drive

if [ -e $HOME/.bundle/GOOGLE_DIR_ID ]; then
  BUNDLE_PARENT_ID=`cat $HOME/.bundle/GOOGLE_DIR_ID`
else
  echo "***error: the file $HOME/.bundle/GOOGLE_DIR_ID containing"
  echo "          the ID of the google drive upload directory does not exit"
  exit
fi

if [ ! -e $GDRIVE ] ; then
  echo "***error: the program $GDRIVE used to upload files to google drive does not exist"
  exit
fi

if [ "$platform" == "win" ]; then
  ext=.exe
else
  ext=.sh
fi

file=${BUNDLE_BASE}$ext
shafile=${BUNDLE_BASE}.sha1

upload=1
if [ ! -e $BUNDLE_DIR/$file ]; then
  echo "$BUNDLE_DIR/file doesn't exist"
  upload=
fi
if [ ! -e $BUNDLE_DIR/$shafile ]; then
  echo "$BUNDLE_DIR/$shafile doesn't exist"
  upload=
fi
if [ "$upload" == "1" ]; then
  if [ "$erase" == "1" ]; then
    $GDRIVE list  | grep ${NIGHTLY}$platform$ext | grep SMV | awk '{ system("~/bin/gdrive delete -i " $1)} '
  fi
  echo ""
  echo "------------------------------------------------------"
  echo "------------------------------------------------------"
  echo "uploading $BUNDLE_DIR/$file"
  echo ""
  $GDRIVE upload -p $BUNDLE_PARENT_ID -f $BUNDLE_DIR/$file
  nfiles=`$GDRIVE list  | grep $file | wc -l`
  if [ $nfiles -eq 0 ]; then
    echo "*** warning: The bundle file $file failed to upload to google drive"
  else
    if [ "$erase_local" == "1" ]; then
      echo "$BUNDLE_DIR/$file uploaded.  Erasing from $BUNDLE_DIR"
      rm -f $BUNDLE_DIR/$file
    else
      echo "$BUNDLE_DIR/$file uploaded."
    fi
  fi
  echo ""
  echo "------------------------------------------------------"
  echo "------------------------------------------------------"
  echo uploading $BUNDLE_DIR/$shafile
  echo ""
  $GDRIVE upload -p $BUNDLE_PARENT_ID -f $BUNDLE_DIR/$shafile
  nfiles=`$GDRIVE list  | grep $shafile | wc -l`
  if [ $nfiles -eq 0 ]; then
    echo "*** warning: The sha1 file $sha1file failed to upload to google drive"
  else
    if [ "$erase_local" == "1" ]; then
      echo "$BUNDLE_DIR/$shafile uploaded.  Erasing from $BUNDLE_DIR"
      rm -f $BUNDLE_DIR/$shafile
    else
      echo "$BUNDLE_DIR/$shafile uploaded."
    fi
  fi
else
  if [ ! -e $BUNDLE_DIR/$file ]; then
    echo "*** warning: The bundle file $BUNDLE_DIR/$file  does not exist"
  fi
  if [ ! -e $BUNDLE_DIR/$shafile ]; then
    echo "*** warning: The sha1 file $BUNDLE_DIR/$shafile  does not exist"
  fi
fi
