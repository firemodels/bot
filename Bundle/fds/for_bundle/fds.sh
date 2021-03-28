#!/bin/bash

default_dir=
exe=fds
casedir=
while getopts 'd:De:' OPTION
do
case $OPTION  in
  d)
   casedir="$OPTARG"
   ;;
  D)
   default_dir=1
   ;;
  e)
   exe="$OPTARG"
   ;;
esac
done
shift $(($OPTIND-1))
case=$1

if [ "$default_dir" != "" ]; then
  casedir=`basename $case .fds`
fi

if [ "$casedir" != "" ]; then
  if [ ! -d $casedir ]; then
    mkdir $casedir
  fi
  cp $case $casedir/.
  cd $casedir
fi
$exe $case

