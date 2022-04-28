#!/bin/bash
OUT=$1

touch complete

make --makefile ../makefile clean &> /dev/null
./make_fds.sh &> $OUT

rm -f complete
