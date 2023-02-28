#!/bin/bash
CUR=`pwd`
showrepos="bot cad cfast cor exp fds fig out radcal smv"
showrepos="bot cfast fds smv"
setrepos="bot cfast fds smv"
BRANCH=master
SHOW=1

function usage {
echo "Show or Set branches"
echo ""
echo "Options:"
echo "-h - display this message"
echo "-b branch - set branch to branch (default: $BRANCH)"
echo "-s - show branches on $showrepos"
echo "-S - set branches on $setrepos"
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

while getopts 'b:hsS' OPTION
do
case $OPTION  in
  b)
   BRANCH="$OPTARG"
   ;;
  h)
   usage;
   ;;
  s)
   SHOW=1
   ;;
  S)
   SHOW=
   ;;
esac
done
shift $(($OPTIND-1))

if [ "$SHOW" == "1" ]; then
   repos=$showrepos
else
   repos=$setrepos
fi

for repo in $repos
do 
  echo $repo
  cd $FMROOT/$repo
  if [ "$SHOW" == "1" ]; then
    git branch -a
  else
    git checkout $BRANCH
  fi
  echo
done

cd $CURDIR
