#!/bin/bash
speed=`grep name /proc/cpuinfo | awk '{print $NF}'` 
echo $speed
