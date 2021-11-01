#!/bin/bash
todir=$1

file=/etc/fstab
base=`basename $file`
grep nfs  $file > $todir/${base}.`hostname -s`
echo ${base}.`hostname -s`
