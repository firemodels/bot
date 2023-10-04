#!/bin/bash
OPTION=$1

# -c clean repos
# -b use existing branches
# -J use intel compilers

time ./run_smokebot.sh -s ../../smokebot_cache -c -b -J $OPTION -q none
# time ./run_smokebot.sh -c -b -J $OPTION -q none
