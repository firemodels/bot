#!/bin/bash
OUT=$1
EXE=$2

make --makefile ../makefile clean &> /dev/null
./make_fds.sh &> $OUT
if [ "$EXE" != "" ]; then
  if [ ! -x $EXE ]; then
    git clean -dxf >& /dev/null
    echo "----------------------------------" >> $OUT 2>&1
    echo first attempt at building fds failed >> $OUT 2>&1
    ./make_fds.sh                             >> $OUT 2>&1
  fi
fi

rm -f compiling
