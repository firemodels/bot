#!/bin/bash
# ---------------------------- usage ----------------------------------

function usage {
  echo "Usage: fds.sh [options ]  casename.fds"
  echo ""
  echo "fds.sh runs fds "
  echo " -e exe: run case using exe"
  echo " -y dir: run case in directory dir"
  echo " -Y    : run case in directory casename"
  exit
}

use_defaultdir=
exe=fds
casedir=
while getopts 'e:hy:Y' OPTION
do
case $OPTION  in
  e)
   exe="$OPTARG"
   ;;
  h)
   usage
   exit
   ;;
  y)
   casedir="$OPTARG"
   ;;
  Y)
   use_defaultdir=1
   ;;
esac
done
shift $(($OPTIND-1))
case=$1

if [ "$use_defaultdir" != "" ]; then
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
