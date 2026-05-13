#!/bin/bash

directory=$1

cd ~/$directory
rev=`git describe --abbrev=7 --dirty`
branch=`git branch | grep \* | awk '{print $2}'`
echo $rev/$branch
