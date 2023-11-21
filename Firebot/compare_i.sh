#!/bin/bash

firebotdir=`pwd`
cd ../..
repo=`pwd`
cd $firebotdir
fdsrepo=$repo/fds

FDS_SUMMARY_DIR=$fdsrepo/Manuals/FDS_Summary
OUTPUT_DIR="$firebotdir/output"

CURDIR=`pwd`
cd $botrepo/Firebot
./compare_images.sh $FDS_SUMMARY_DIR/images $FDS_SUMMARY_DIR/diffs/images $OUTPUT_DIR/error_images 
