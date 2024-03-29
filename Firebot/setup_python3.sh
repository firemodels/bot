#!/bin/bash
# setup environment for python 3 and run the hello_world.py to test the setup

curdir=`pwd`
cd ../..
reporoot=`pwd`

cd $reporoot/fds/.github
python3 -m venv fds_python_env
source fds_python_env/bin/activate
pip install -r requirements.txt
cd $reporoot/fds/Utilities/Python
python hello_world.py
cd $curdir
