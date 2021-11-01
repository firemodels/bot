#!/bin/bash
todir=$1

file=memory
base=`basename $file`
memory=`grep MemTotal /proc/meminfo | awk '{print $2}'` 
div=1000
memory=`echo $((memory / div))`
echo $memory
