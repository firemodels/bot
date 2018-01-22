#!/bin/bash
ps -el | awk '{if(NR>1&&$3>1000){system("kill -9 " $4)}}'
