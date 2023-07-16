#!/bin/bash
OUT=$1

touch compiling

make --makefile ../makefile clean &> /dev/null
./make_fds.sh &> $OUT

rm -f compiling
