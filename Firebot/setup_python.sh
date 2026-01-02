#!/bin/bash
# setup environment for python
# usage: source ./setup_python.sh

setup_python_pwd=$(pwd)
cd ../..
reporoot=$(pwd)
cd $reporoot/fds/Utilities/Python
source ./setup_python_env.sh --batchmode
cd "$setup_python_pwd"
