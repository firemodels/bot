#!/bin/bash
CUR=`pwd`
allrepos="bot cad cfast cor exp fds fig out radcal smv test_bundles test7_bundles"

function usage {
echo "Clean repos $allrepos if they exist"
echo ""
echo "Options:"
echo "-h - display this message"
exit
}

FMROOT=
if [ -e ../.gitbot ]; then
   cd ../..
   FMROOT=`pwd`
else
   echo "***error: this script must be run from the bot/Scripts directory"
   exit
fi

while getopts 'h' OPTION
do
case $OPTION  in
  h)
   usage;
   ;;
esac
done
shift $(($OPTIND-1))

CLEAN_REPO ()
{
  local repo=$1
  repodir=$FMROOT/$repo

  echo "------------- $repo -------------------------------------------"
  if [ ! -e $repodir ]; then
     echo "Skipping, $repo does not exist"
     return
  fi
  cd $repodir
  git checkout master
  git clean -dxf
}

for repo in $allrepos
do 
  echo
  CLEAN_REPO $repo
done

cd $CURDIR
