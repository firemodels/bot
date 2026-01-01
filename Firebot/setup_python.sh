#!/bin/bash
# setup environment for python and run the hello_world.py to test the setup
# usage: source ./setup_python.sh

curdir=`pwd`
cd ../..
reporoot=`pwd`
cd $reporoot/fds/Utilities/Python
source ./setup_python_env.sh --batchmode
# this reverses set -e performed in setup_pythyon_env.sh 
# which was causing firebot to crash if any function
# or script called by firebot failed
set +e
python hello_world.py
cd $curdir
