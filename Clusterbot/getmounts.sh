#!/bin/bash
todir=$1

file=file_mounts
base=`basename $file`
df | grep ':'  | grep -v Filesystem | awk '{print $1 $6}' | sort > $todir/${base}.`hostname -s`
echo ${base}.`hostname -s`
