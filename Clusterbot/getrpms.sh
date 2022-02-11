#!/bin/bash
todir=$1
prefix=$2

HOST=`hostname -s`
rpm -qa | grep -v hponcfg | sort > $todir/${prefix}rpm_${HOST}.txt
