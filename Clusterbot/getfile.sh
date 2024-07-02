#!/bin/bash
file=$1
todir=$2

base=`basename $file`
grep -v ^# $file > $todir/${base}.`hostname -s`
echo ${base}.`hostname -s`
