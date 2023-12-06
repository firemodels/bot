#!/bin/bash
OPTION=$1

# -c clean repos
# -b use existing branches
# -J use intel compilers
# -s cache_dir use results previously computed
# -S build smokeview with the Intel Sanitize option

time ./run_smokebot.sh -S -s ../../smokebot_cache -c -b -J $OPTION -q none
# time ./run_smokebot.sh -c -b -J $OPTION -q none
