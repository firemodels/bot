#!/bin/bash
todir=$1

file=/etc/fstab
base=`basename $file`
grep nfs  $file | sort > $todir/${base}.`hostname -s`
echo ${base}.`hostname -s`
