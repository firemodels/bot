#!/bin/bash

#---------------------------------------------
#                   usage
#---------------------------------------------

function usage {
echo ""
echo "run_bundlebot.sh usage"
echo ""
echo "This script builds FDS and Smokeview apps and generates a bundle using either the"
echo "specified fds and smv repo revisions or revisions from the latest firebot pass."
echo ""
echo "Options:"
echo "-c - bundle without warning about cloning/erasing fds and smv repos"
echo "-f - force this script to run"
echo "-F - fds repo hash/tag"
echo "-h - display this message"

FIREBOT_HOST_MSSG=
if [ "$FIREBOT_HOST" != "" ]; then
  FIREBOT_HOST_MSSG="[default: $FIREBOT_HOST]"
fi
echo "-H host - firebot/smokebot host $FIREBOT_HOST_MSSG"

if [ "$MAILTO" != "" ]; then
  echo "-m mailto - email address [default: $MAILTO]"
else
  echo "-m mailto - email address"
fi

echo "-r - create a release bundle"
echo "-S - smv repo hash/tag"
exit 0
}

#---------------------------------------------
#                   CHK_REPO
#---------------------------------------------

CHK_REPO ()
{
  local repodir=$1

  if [ ! -e $repodir ]; then
     echo "***error: the repo directory $repodir does not exist."
     echo "          Aborting the make_bundle script"
     return 1
  fi
  return 0
}

#---------------------------------------------
#                   CD_REPO
#---------------------------------------------

CD_REPO ()
{
  local repodir=$1
  local branch=$2

  CHK_REPO $repodir || return 1

  cd $repodir
  if [ "$branch" != "current" ]; then
  if [ "$branch" != "" ]; then
     CURRENT_BRANCH=`git rev-parse --abbrev-ref HEAD`
     if [ "$CURRENT_BRANCH" != "$branch" ]; then
       echo "***error: was expecting branch $branch in repo $repodir."
       echo "Found branch $CURRENT_BRANCH. Aborting firebot."
       return 1
     fi
  fi
  fi
  return 0
}

#---------------------------------------------
#                   update_repo
#---------------------------------------------

UPDATE_REPO()
{
   local reponame=$1
   local branch=$2

   CD_REPO $repo/$reponame $branch || return 1

   echo Updating $branch on repo $repo/$reponame
   git fetch origin
   git merge origin/$branch
   return 0
}


#-------------------- start of script ---------------------------------

if [ -e $HOME/.bundle/bundle_config.sh ]; then
  source $HOME/.bundle/bundle_config.sh
else
  echo ***error: configuration file $HOME/.bundle/bundle_config.sh is not defined
  exit 1
fi
FIREBOT_HOST=$bundle_hostname
FIREBOT_HOME=$bundle_firebot_home

MAILTO=
if [ "$EMAIL" != "" ]; then
  MAILTO=$EMAIL
fi
FDS_RELEASE=
SMV_RELEASE=
ECHO=
PROCEED=

FORCE=
RELEASE=
BRANCH=nightly

while getopts 'cfF:hH:m:rS:v' OPTION
do
case $OPTION  in
  c)
   PROCEED=1
   ;;
  f)
   FORCE="-f"
   ;;
  F)
   FDS_RELEASE="$OPTARG"
   ;;
  h)
   usage
   ;;
  H)
   FIREBOT_HOST="$OPTARG"
   ;;
  m)
   MAILTO="$OPTARG"
   ;;
  S)
   SMV_RELEASE="$OPTARG"
   ;;
  r)
   BRANCH=release
   ;;
  v)
   ECHO=echo
   ;;
esac
done
shift $(($OPTIND-1))

if [ "$PROCEED" == "" ]; then
  echo ""
  echo "------------------------------------------------------------"
  echo "------------------------------------------------------------"
  echo "You are about to erase and then clone the fds and smv repos."
  echo "Press any key to continue or <CTRL> c to abort."
  echo To avoid this warning, use the -c option on the command line
  echo "------------------------------------------------------------"
  echo "------------------------------------------------------------"
  read val
fi


# Linux or OSX
JOPT="-J"
if [ "`uname`" == "Darwin" ] ; then
  JOPT=
fi

# both or neither RELEASE options must be set
if [ "$FDS_RELEASE" != "" ]; then
  if [ "$SMV_RELEASE" != "" ]; then
    FDS_RELEASE="-x $FDS_RELEASE"
    SMV_RELEASE="-y $SMV_RELEASE"
  fi
fi
if [ "$FDS_RELEASE" == "" ]; then
  SMV_RELEASE=""
fi
if [ "$SMV_RELEASE" == "" ]; then
  FDS_RELEASE=""
fi

FIREBOT_BRANCH="-R $BRANCH"
BUNDLE_BRANCH="-b $BRANCH"

# email address
if [ "$MAILTO" != "" ]; then
  MAILTO="-m $MAILTO"
fi

curdir=`pwd`

commands=$0
DIR=$(dirname "${commands}")
cd $DIR
DIR=`pwd`

cd ../..
repo=`pwd`

cd $DIR

#*** update bot and webpages repos
UPDATE_REPO bot      master     || exit 1
UPDATE_REPO webpages nist-pages || exit 1

#*** build apps
cd $curdir
cd ../Firebot
$ECHO ./run_firebot.sh $FORCE -c -C -B -g $FIREBOT_HOST -G $FIREBOT_HOME $JOPT $FDS_RELEASE $SMV_RELEASE $FIREBOT_BRANCH -T $MAILTO || exit 1

#*** generate and upload bundle
cd $curdir
$ECHO ./bundlebot.sh $FORCE $BUNDLE_BRANCH -p $FIREBOT_HOST $FDS_RELEASE $SMV_RELEASE -w -g
