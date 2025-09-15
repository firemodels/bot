#!/bin/bash

CURDIR=`pwd`
cd ../../smv/Manuals/SMV_Summary
export SMV_SUMMARY_DIR=`pwd`
cd $CURDIR
cd output
export OUTPUT_DIR=`pwd`
export TOLERANCE=0.2
cd $CURDIR

../Firebot/compare_images.sh $SMV_SUMMARY_DIR/images $SMV_SUMMARY_DIR/diffs/images $OUTPUT_DIR/error_images $TOLERANCE
