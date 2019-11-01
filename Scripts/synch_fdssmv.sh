#!/bin/bash
acct=$1
host=$2
branch=$3

return_code=0

curdir=`pwd`
scriptdir=`dirname "$0"`
cd $scriptdir/../../fds
fdsrepo=`pwd`

cd $curdir
cd $scriptdir/../../smv
smvrepo=`pwd`

eval ls $acct
