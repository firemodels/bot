#!/bin/bash
DIR=$1
OUT=$2
COMPLETE=$3

cd $DIR
touch $COMPLETE

make --makefile ../makefile clean &> /dev/null
./make_fds.sh &> $OUT

rm -f $COMPLETE
