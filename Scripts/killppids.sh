#!/bin/bash
cat $1 | awk '{system("sh ./getpid.sh "$1)}' | awk '{system("sh killppid.sh "$1)}'
