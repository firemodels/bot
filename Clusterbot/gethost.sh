#!/bin/bash
todir=$1

file=/etc/hosts
base=`basename $file`
grep -v localhost /etc/hosts >  $todir/${base}.`hostname -s`
echo ${base}.`hostname -s`
