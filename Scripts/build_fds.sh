#!/bin/bash
OUT=$1
EXE=$2

make --makefile ../makefile clean &> /dev/null
./make_fds.sh &> $OUT
if [ "$EXE" != "" ]; then
  if [ ! -x $EXE ]; then
    git clean -dxf >& /dev/null
    ./make_fds.sh &> $OUT
  fi
fi

rm -f compiling
