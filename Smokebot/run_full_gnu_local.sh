#!/bin/bash
OPTION=$1

# -c clean repos
# -b use existing branches
# -C use gnu compilers
./run_smokebot.sh -C -c -b $OPTION -q none
