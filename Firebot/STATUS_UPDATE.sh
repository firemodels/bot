#!/bin/bash
curdir=`pwd`
cd ../..
repo=`pwd`
WEBBRANCH=nist-pages
cd $curdir
./status_updatepub.sh $repo/webpages $WEBBRANCH
