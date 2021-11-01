#!/bin/bash
todir=$1

file=file_mounts
base=`basename $file`
df -t nfs  | sort > $todir/${base}.`hostname -s`
echo ${base}.`hostname -s`
