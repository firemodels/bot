#!/bin/bash

directory=$1

cd ~/$directory
rev=`git describe --dirty`
branch=`git branch | grep \* | awk '{print $2}'`
echo $rev/$branch
