#!/bin/bash
pidfiles=$1
if [ -e $pidfiles ]; then
  cat $pidfiles | awk '{system("sh ./getpid.sh "$1)}' | awk '{system("sh killppid.sh "$1)}'
fi
