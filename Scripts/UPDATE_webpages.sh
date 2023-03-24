#!/bin/bash

directory=$1

cd ~/$directory

git checkout nist-pages
git remote update
git merge origin/nist-pages
git describe --abbrev=7 --dirty --long
