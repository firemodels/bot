#!/bin/bash
WEB_DIR_BASE=$1
WEB_DIR=
if [WEB_DIR_BASE!="" ]; then
  WEB_DIR=/var/www/html/$WEB_DIR_BASE
fi

firebotdir=`pwd`
cd ../..
repo=`pwd`
cd $firebotdir
fdsrepo=$repo/fds
botrepo=$repo/bot

FDS_SUMMARY_DIR=$fdsrepo/Manuals/FDS_Summary
OUTPUT_DIR="$firebotdir/output"

CURDIR=`pwd`
cd $botrepo/Firebot
./compare_images.sh $FDS_SUMMARY_DIR/images $FDS_SUMMARY_DIR/diffs/images $OUTPUT_DIR/error_images

if [ "$WEB_DIR" != "" ]; then
  if [ -d $WEB_DIR ]; then
    CUR_DIR=`pwd`
    cd $WEB_DIR
    rm -r images manuals diffs *.html
    cp -r $FDS_SUMMARY_DIR/* .
    rm *template.html
    cd $CUR_DIR
    UPDATED_WEB_IMAGES=1
  fi
fi

