#!/bin/bash
OUT=$1

make --makefile ../makefile clean &> /dev/null
./make_fds.sh &> $OUT

rm -f compiling
