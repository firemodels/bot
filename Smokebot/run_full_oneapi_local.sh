#!/bin/bash
OPTION=$1

# -c clean repos
# -b use existing branches
# -J use intel compilers
./run_smokebot.sh -c -b -J $OPTION -q none
