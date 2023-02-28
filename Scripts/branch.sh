#!/bin/bash
CUR=`pwd`
showrepos="bot cad cfast cor exp fds fig out radcal smv"
setrepos="bot fds smv"
BRANCH=master
SHOW=1

function usage {
echo "Show or Set branches"
echo ""
echo "Options:"
echo "-h - display this message"
echo "-b branch - set branch to branch (default: $BRANCH)"
echo "-d - display branch on $showrepos repos"
echo "-s - set branch on $setrepos repos"
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

while getopts 'b:hds' OPTION
do
case $OPTION  in
  b)
   BRANCH="$OPTARG"
   ;;
  h)
   usage;
   ;;
  d)
   SHOW=1
   ;;
  s)
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
    git branch
  else
    git checkout $BRANCH
  fi
  echo
done

cd $CURDIR
