#!/bin/bash

# $SMV_SUMMARY_DIR/images $SMV_SUMMARY_DIR/diffs/images $OUTPUT_DIR/error_images $TOLERANCE >& $OUTPUT_DIR/stage5_image_compare
CURDIR=`pwd`
cd ../../smv/Manuals/SMV_Summary
export SMV_SUMMARY_DIR=`pwd`
cd $CURDIR
cd output
export OUTPUT_DIR=`pwd`
export TOLERANCE=0.2
echo SMV_SUMMARY_DIR=$SMV_SUMMARY_DIR
echo OUTPUT_DIR=$OUTPUT_DIR
echo TOLERANCE=$TOLERANCE
