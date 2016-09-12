#!/bin/bash
CURDIR=`pwd`

fdsrepos="exp fds out smv"
smvrepos="cfast fds smv"
cfastrepos="cfast exp smv"
allrepos="cfast cor exp fds out radcal smv"
repos=$fdsrepos

function usage {
echo "Create repos used by cfast, fds and/or smokview"
echo ""
echo "Options:"
echo "-a - setup all available repos: "
echo "    $allrepos"
echo "-c - setup repos used by cfastbot: "
echo "    $cfastrepos"
echo "-f - setup repos used by firebot: "
echo "    $fdsrepos"
echo "-s - setup repos used by smokebot: "
echo "    $smvrepos"
echo "-h - display this message"
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

while getopts 'acfr:sh' OPTION
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
  r)
   FMROOT=$OPTARG;
   ;;
  s)
   repos=$smvrepos;
   ;;
esac
done
shift $(($OPTIND-1))

if [ "x$FMROOT" == "x" ]; then
   echo "***Error: repo directory not defined."
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

cd $FMROOT/bot
HEADER=`git remote -v | grep origin | head -1 | awk  '{print $2}' | awk -F ':' '{print $1}'`
if [ "$HEADER" == "git@github.com" ]; then
   HEADER="git@github.com:" 
   GITUSER=`git remote -v | grep origin | head -1 | awk -F ':' '{print $2}' | awk -F\/ '{print $1}'`
else
   HEADER="https://github.com/"
   GITUSER=`git remote -v | grep origin | head -1 | awk -F '.' '{print $2}' | awk -F\/ '{print $2}'`
fi

echo "You are about to clone the repos:"
echo "$repos "
echo "from $HEADERS$GITUSER"
echo ""
echo "Press any key to continue or <CTRL> c to abort."
echo "Type $0 -h for other options"
read val

for repo in $repos
do 
  echo
  repodir=$FMROOT/$repo
  echo "-------------------------------"
  if [ -e $repodir ]; then
     echo Skipping $repo.  The directory $repodir already exists.
  else
     cd $FMROOT
     RECURSIVE=
     if [ "$repo" == "exp" ]; then
        RECURSIVE=--recursive
     fi
     git clone $RECURSIVE $HEADER$GITUSER/$repo.git
     if [ "$GITUSER" != "firemodels" ]; then
        echo setting up remote tracking with firemodels
        cd $repodir
        git remote add firemodels ${HEADER}firemodels/$repo.git
        git remote update
     fi
  fi
done
cd $CURDIR
