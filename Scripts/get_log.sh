#!/bin/bash
CURDIR=`pwd`
cd ../../fds
FDSREPO=`pwd`
cd $FDSREPO
git log --no-merges --date=short  --format="%h;%cnn;%cd;%s" -n 100  Source > $CURDIR/revisions.txt
