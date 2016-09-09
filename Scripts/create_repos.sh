#!/bin/bash
GITUSER=`git remote -v | head -1 | awk -F ':' '{print $2}' | awk -F\/ '{print $1}'`
fdsrepos="exp fds out smv"
smvrepos="cfast fds smv"
cfastrepos="cfast exp smv"
allrepos="cfast cor exp fds out radcal smv"
repos=$fdsrepos
HEADER="git@github.com\:"

function usage {
echo "Create repos used by cfast, fds and/or smokview"
echo ""
echo "Options:"
echo "-a - setup all repos: "
echo "    $allrepos"
echo "-c - setup repos used by cfastbot: "
echo "    $cfastrepos"
echo "-f - setup repos used by firebot: "
echo "    $fdsrepos"
echo "-s - setup repos used by smokebot: "
echo "    $smvrepos"
echo "-S - use https protocol to communicate with github"
echo "-h - display this message"
exit
}

while getopts 'acfshS' OPTION
do
case $OPTION  in
  a)
   repos=$allrepos;
   ;;
  c)
   repos=$cfastrepos;
   ;;
  f)
   repos=$fdsrepos;
   ;;
  h)
   usage;
   ;;
  s)
   repos=$smvrepos;
   ;;
  S)
   HEADER="https\://github.com/"
   ;;
esac
done
shift $(($OPTIND-1))

echo "You are about to clone the repos:"
echo "$repos "
echo "from git@github.com:$GITUSER"
echo ""
echo "Press any key to continue or <CTRL> c to abort."
echo "Type $0 -h for other options"
read val

CURDIR=`pwd`
cd ../..
FIREMODELS=`pwd`
for repo in $repos
do 
  echo
  repodir=$FIREMODELS/$repo
  echo "-------------------------------"
  if [ -e $repodir ]; then
     echo Skipping $repo.  The directory $repodir already exists.
  else
     cd $FIREMODELS
     if [ "$repo" == "exp" ]; then
        git clone  --recursive git@github.com\:$GITUSER/$repo.git
     else
        git clone git@github.com\:$GITUSER/$repo.git
     fi
     if [ "$GITUSER" != "firemodels" ]; then
        echo setting up remote tracking
        cd $repodir
        git remote add firemodels git@github.com\:firemodels/$repo.git
        git remote update
     fi
  fi
done
echo repo creation complated
cd $CURDIR
