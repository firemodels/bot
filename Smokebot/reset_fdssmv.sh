#!/bin/bash

curdir=`pwd`
scriptdir=`dirname "$0"`
cd $scriptdir/../../fds
fdsrepo=`pwd`

cd $curdir
cd $scriptdir/../../smv
smvrepo=`pwd`

cd $fdsrepo
git checkout master >& /dev/null

cd $smvrepo
git checkout master >& /dev/null

cd $curdir
return 0
