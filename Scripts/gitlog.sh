#!/bin/bash
repo=$1
month=$2
year=$3

if [ "$year" == "" ]; then
   year=$(date +%Y)
fi
if [ "$month" == "" ]; then
   month=$(date +%m)
fi
if [ "$repo" == "" ]; then
   repo=smv
fi
OWNER=`whoami`

fromdate=${year}-${month}-1
todate=${year}-${month}-31


CURDIR=`pwd`
cd ../..
GITROOT=`pwd`
cd $CURDIR

repodir=$GITROOT/$repo
if [ ! -e $repordir ]; then
  echo ***error: repo $repodir does not exist
  exit 
fi

outfile=${repo}_${year}_${month}.log

cd $repodir
#echo "git --no-pager log --no-merges --abbrev-commit --since=$fromdate --until=$todate --pretty=oneline --date=short  >& $outfile"
git --no-pager log --no-merges --abbrev-commit --since=$fromdate --until=$todate --pretty=format:"%ai %an %s"  | grep $OWNER



cd $CURDIR

