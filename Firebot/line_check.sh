#!/bin/bash

#---------------------------------------------
#                   find_CRLF
#---------------------------------------------

find_CRLF()
{
  local curdir=`pwd`
  local repodir=$1
  local reponame=$2

  crlf_temp=/tmp/crlf.$$

  cd $repodir
  grep -IURl --exclude="*.pdf" --exclude-dir=".git"  --exclude-dir="output" $'\r'  > $crlf_temp
  nlines=`cat $crlf_temp | wc -l`
  if [ $nlines -gt 0 ]; then
    echo "$reponame files with CRLF line endings: "
    cat $crlf_temp
    rm $crlf_temp
  else
    echo $reponame: none
  fi

  cd $curdir
}

WARNING_LOG=warnings
CRLF_WARNINGS=crlf_warnings
CURDIR=`pwd`
cd ../..
repo=`pwd`
cd $CURDIR

rm -f $CRLF_WARNINGS
rm -f $WARNING_LOG
echo Checking for DOS line endings
find_CRLF $repo/bot bot
find_CRLF $repo/exp exp
find_CRLF $repo/fds fds
find_CRLF $repo/out out
find_CRLF $repo/smv smv
