#!/bin/bash
# setup environment for python 3 and run the hello_world.py to test the setup
# usage: source ./setup_python3.sh

curdir=`pwd`
cd ../..
reporoot=`pwd`

cd $reporoot/fds/Utilities/Python
source ./setup_python_env.sh --batchmode
python hello_world.py
cd $curdir
