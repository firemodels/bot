#!/bin/bash
todir=$1

file=memory
base=`basename $file`
memory=`grep MemTotal /proc/meminfo | awk '{print $2}'` 
memory=`echo $((memory / 1024))`
memory=`echo $((memory / 16))`
memory=`echo $((memory * 16))`
echo $memory
