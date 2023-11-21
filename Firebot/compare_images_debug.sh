#!/bin/bash
WEB_DIR_BASE=$1
WEB_DIR=
if [ "$WEB_DIR_BASE" != "" ]; then
  WEB_DIR=/var/www/html/$WEB_DIR_BASE
fi
SCRIPTNAME=`basename $0`

CURDIR=`pwd`
BASEDIR=`basename $CURDIR`
if [ "$BASEDIR" != "Firebot" ]; then
  echo "***error: compare_images.sh must be run in the Firebot or Smokebot directory"
  exit
fi

firebotdir=`pwd`
cd ../..
repo=`pwd`
cd $firebotdir
fdsrepo=$repo/fds
botrepo=$repo/bot

FDS_SUMMARY_DIR=$fdsrepo/Manuals/FDS_Summary
OUTPUT_DIR="$firebotdir/output"

cp $fdsrepo/Manuals/FDS_User_Guide/SCRIPT_FIGURES/*.png         $FDS_SUMMARY_DIR/images/user/.
cp $fdsrepo/Manuals/FDS_Verification_Guide/SCRIPT_FIGURES/*.png $FDS_SUMMARY_DIR/images/verification/.

cd $botrepo/Firebot
./compare_images.sh $FDS_SUMMARY_DIR/images $FDS_SUMMARY_DIR/diffs/images $OUTPUT_DIR/error_images

if [ "$WEB_DIR" != "" ]; then
  if [ -d $WEB_DIR ]; then
    CUR_DIR=`pwd`
    cd $WEB_DIR
    rm -rf images manuals diffs *.html
    cp -r $FDS_SUMMARY_DIR/* .
    rm -f *template.html
    cd $CUR_DIR
    UPDATED_WEB_IMAGES=1
  fi
fi

