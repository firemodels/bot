#!/bin/bash
speed=`grep name /proc/cpuinfo | awk '{print $10}'` 
echo $speed
