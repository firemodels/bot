#!/bin/bash
WEB_DIR_BASE=$1
WEB_DIR=
if [ "$WEB_DIR_BASE" != "" ]; then
  TEST=
  WEB_DIR=/var/www/html/$WEB_DIR_BASE
  TEST=$WEB_DIR/test
  touch $TEST >& /dev/null
  if [ -e $TEST ]; then
    rm -f $TEST
  else
    WEB_DIR=
  fi
fi
SCRIPTNAME=`basename $0`

CURDIR=`pwd`
BASEDIR=`basename $CURDIR`
if [ "$BASEDIR" != "Firebot" ]; then
  echo "***error: $SCRIPTNAME must be run in the Firebot directory"
  exit
fi

firebotdir=`pwd`
cd ../..
repo=`pwd`
cd $firebotdir
fdsrepo=$repo/fds
botrepo=$repo/bot

FDS_SUMMARY_DIR=$fdsrepo/Manuals/FDS_Summary

echo "copying user guide pngs"
cp $fdsrepo/Manuals/FDS_User_Guide/SCRIPT_FIGURES/*.png         $FDS_SUMMARY_DIR/images/user/.

echo "copying verification guide pngs"
cp $fdsrepo/Manuals/FDS_Verification_Guide/SCRIPT_FIGURES/*.png $FDS_SUMMARY_DIR/images/verification/.

cd $botrepo/Firebot
./compare_images.sh $FDS_SUMMARY_DIR/images $FDS_SUMMARY_DIR/diffs/images error_images

if [ "$WEB_DIR" != "" ]; then
  cd $WEB_DIR
  rm -rf images manuals diffs *.html
  cp -r $FDS_SUMMARY_DIR/* .
  rm -f *template.html
  echo comparison images in $WEB_DIR
else
  echo comparison images in $FDS_SUMMARY_DIR
fi

