#!/bin/bash

directory=$1

cd ~/$directory
git describe --dirty 
git branch | grep \* | awk '{print $2}'
