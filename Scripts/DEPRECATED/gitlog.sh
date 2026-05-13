#!/bin/bash
function usage {
echo "Create repos used by cfast, fds and/or smokview"
echo ""
echo "Options:"
echo "-h      - display this message"
echo "-m m    - month 1 to 12, default: $month"
echo "-u user - user, default: $user"
echo "-r repo - default: $repo"
echo "-y y    - year, default: $year"
exit
}

year=$(date +%Y)
month=$(date +%m)
repo=smv
user=`whoami`
showinput=

while getopts 'hm:r:u:vy:' OPTION
do
case $OPTION  in
  h)
   usage
   ;;
  m)
   month=$OPTARG;
   ;;
  r)
   repo=$OPTARG;
   ;;
  u)
   user=$OPTARG;
   ;;
  v)
   showinput=1
   ;;
  y)
   year=$OPTARG;
   ;;
esac
done
shift $(($OPTIND-1))


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
if [ "$showinput" != "" ]; then
  echo cd $repodir
  echo "git --no-pager log --no-merges --abbrev-commit --since=$fromdate --until=$todate --pretty=format:\"%ai %an %s\"  | grep $user"
else
  git --no-pager log --no-merges --abbrev-commit --since=$fromdate --until=$todate --pretty=format:"%ai %an %s"  | grep $user
fi



cd $CURDIR

