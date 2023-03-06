#!/bin/bash
FROM_DIR=$1
FROM_FILE=$2
PLATFORM=$3
EXT=$4
RELEASE_BUNDLE=$5

scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

cd $scriptdir

GDRIVE=~/bin/gdrive
GOOGLE_ID=`cat $HOME/.bundle/GOOGLE_SMOKEVIEW_ID`

if [ ! -e $GDRIVE ] ; then
  echo "***error: the program $GDRIVE used to upload files to google drive does not exist"
  exit
fi
if [ ! -e $HOME/$FROM_DIR/$FROM_FILE ] ; then
  echo "***error: $FROM_FILE does not exist in $HOME/$FROM_DIR"
  exit
fi

$GDRIVE list  | grep $PLATFORM | grep $EXT | awk '$2 ~ /^SMV/ { system("~/bin/gdrive delete -i " $1)} '
echo "***uploading $FROM_FILE to Google Drive"
$GDRIVE upload -p $GOOGLE_ID -f $HOME/$FROM_DIR/$FROM_FILE >& /dev/null
nfiles=`$GDRIVE list  | grep $FROM_FILE | wc -l`
if [ $nfiles -eq 0 ]; then
  echo "*** warning: The file $FROM_FILE failed to upload to google drive"
else
  echo "$FROM_FILE uploaded."
fi
echo ""

if [ "$RELEASE_BUNDLE" != "" ]; then
  cd $RELEASE_BUNDLE
  gh release upload TEST_BUNDLES $HOME/$FROM_DIR/$FROM_FILE  --clobber
fi

