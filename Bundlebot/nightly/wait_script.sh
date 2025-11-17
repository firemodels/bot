#!/bin/bash
prog=$1
lockfile=$prog.lock

echo waiting for $prog to finish
sleep 5
while [[  -e $lockfile    ]]; do
   sleep 5
done

