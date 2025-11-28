#!/bin/bash

CURDIR=`pwd`
cd ../../Scripts
./update_repos.sh -m -b
cd $CURDIR

./BuildSmvNightly.sh $*
