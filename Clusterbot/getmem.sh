#!/bin/bash
file=memory
base=`basename $file`
memory=`grep MemTotal /proc/meminfo | awk '{print $2}'` 
memory=`echo $((memory / 1024))`
echo $memory
