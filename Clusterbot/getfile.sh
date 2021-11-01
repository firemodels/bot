#!/bin/bash
file=$1
todir=$2

base=`basename $file`
cp $file $todir/${base}_`hostname -s`
