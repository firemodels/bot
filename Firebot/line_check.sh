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
    echo ""                                                 >> $CRLF_WARNINGS
    echo "$reponame repo text files with dos line endings:" >> $CRLF_WARNINGS
    cat $crlf_temp                                          >> $CRLF_WARNINGS
    rm $crlf_temp
  fi
  cd $curdir
}

#---------------------------------------------
#                   check_CRLF
#---------------------------------------------

check_CRLF()
{

  WARNINGS=
  if [ -e $CRLF_WARNINGS ]; then
    nwarnings=`cat $CRLF_WARNINGS | wc -l`
    if [ $nwarnings -gt 0 ]; then
      WARNINGS=1
      echo ""
      echo "Warning: files with DOS line endings were found"
      echo "see $WARNING_LOG"
      echo "Warning: files with DOS line endings were found" >> $WARNING_LOG
      cat $CRLF_WARNINGS                                   >> $WARNING_LOG
      echo ""                                              >> $WARNING_LOG
      echo ""
    fi
  fi
  if [ "$WARNINGS" == "" ]; then
    echo "*** no files with DOS line endings were found"
  fi
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
echo "   bot repo"
find_CRLF $repo/bot bot

echo "   exp repo"
find_CRLF $repo/exp exp

echo "   fds repo"
find_CRLF $repo/fds fds

echo "   out repo"
find_CRLF $repo/out out

echo "   smv repo"
find_CRLF $repo/smv smv

check_CRLF
