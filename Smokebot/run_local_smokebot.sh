#!/bin/bash
OPTION=$1

# -b use existing branches
# -c clean repos
# -f force a smokebot run
# -J use intel compilers
# -s cache_dir use results previously computed
# -S build smokeview with the Intel Sanitize option

time ./run_smokebot.sh -s ../../smokebot_cache -c -b -J $OPTION -q none
# time ./run_smokebot.sh -c -b -J $OPTION -q none
