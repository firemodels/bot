#!/bin/bash
prog=$*

lockfile=$1.lock
touch $lockfile
$prog
rm $lockfile
