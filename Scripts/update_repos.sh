#!/bin/bash
CUR=`pwd`
allrepos="bot cfast cor exp fds out radcal smv"
BRANCH=master
PUSH=

function usage {
echo "Update the repos $allrepos if they exist"
echo ""
echo "Options:"
echo "-h - display this message"
echo "-p - push updates to remote origin"
exit
}

FMROOT=
if [ -e ../.gitbot ]; then
   cd ../..
   FMROOT=`pwd`
fi
if [ x"$FMROOT" == "x" ]; then
   FMROOT=$FIREMODELS
fi

while getopts 'hpr:' OPTION
do
case $OPTION  in
  h)
   usage;
   ;;
  p)
   PUSH="1";
   ;;
  r)
   FMROOT=$OPTARG;
   ;;
esac
done
shift $(($OPTIND-1))

if [ "x$FMROOT" == "x" ]; then
   echo "***Error: repo location not defined."
   echo "          Rerun in the bot/Scripts directory, or:
   echo "          use the -r option or define the FIREMODELS:
   echo "          environment variable to define a repo location"
   exit
fi
if [ ! -e $FMROOT ]; then
   echo "***Error: The directory $FMROOT does not exist"
   echo "          You need to cd to $FMROOT and clone the bot directory from github"
   exit
fi

for repo in $allrepos
do 
  echo
  repodir=$FMROOT/$repo
  echo "---------------------------------------------------------------"
  if [ -e $repodir ]; then
     cd $repodir
     CURRENT_BRANCH=`git rev-parse --abbrev-ref HEAD`
     if [ "$BRANCH" == "$CURRENT_BRANCH" ]; then
       echo "updating $repo from origin"
       git fetch origin
       git merge origin/$BRANCH
       have_central=`git remote -v | awk '{print $1}' | grep firemodels | wc  -l`
       if [ "$have_central" -gt "0" ]; then
          echo "updating $repo from firemodels"
          git fetch firemodels
          git merge firemodels/$BRANCH
          if [ "$PUSH" == "1" ]; then
             echo "pushing changes in $repo to origin"
             git push origin $BRANCH
          fi
       fi
     else
       echo $BRANCH branch not checkout out in $repo
       echo update skipped
     fi
  else
     echo "$repo does not exist, not updating"
  fi
done
echo
echo repo updating complete
cd $CURDIR
