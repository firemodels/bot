#!/bin/bash
local DIR=$1
local COMMAND=$2
local OUT=$3
local COMPLETE=$4

cd $DIR
touch $COMPLETE
 bash -lc "$COMMAND >& $OUT"
rm -f $COMPLETE
