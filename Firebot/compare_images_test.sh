#!/bin/bash

CURDIR=`pwd`
cd ../../fds/Manuals/FDS_Summary
export FDS_SUMMARY_DIR=`pwd`
cd $CURDIR
cd output
export OUTPUT_DIR=`pwd`
export TOLERANCE=0.1
cd $CURDIR

./compare_images.sh $FDS_SUMMARY_DIR/images $FDS_SUMMARY_DIR/diffs/images $OUTPUT_DIR/error_images
