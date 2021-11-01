#!/bin/bash
todir=$1

HOST=`hostname -s`
rpm -qa | sort > $todir/rpm_${HOST}.txt
