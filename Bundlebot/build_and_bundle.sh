#!/bin/bash

#---------------------------------------------
#                   usage
#---------------------------------------------

function usage {
echo "This script builds FDS and Smokeview apps and genrates a bundle using"
echo "specified fds and smv repo revisions or revisions from the latest firebot pass."
echo ""
echo "Options:"
echo "-f - force this script to run"
echo "-F - fds repo release"
echo "-S - smv repo release"
echo "-h - display this message"
echo "-H host - firebot host or LOCAL if revisions and documents are found at"
echo "          $HOME/.firebot/pass"
if [ "$MAILTO" != "" ]; then
  echo "-m mailto - email address [default: $MAILTO]"
else
  echo "-m mailto - email address"
fi
echo "-v - show settings used to build bundle"
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

FIREBOT_HOST="LOCAL"
MAILTO=
if [ "$EMAIL" != "" ]; then
  MAILTO=$EMAIL
fi
FDS_RELEASE=
SMV_RELEASE=
ECHO=
VERBOSE=

FORCE=

while getopts 'fF:hH:m:S:vV' OPTION
do
case $OPTION  in
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
  v)
   ECHO=echo
   ;;
  V)
   VERBOSE="-V"
   ;;
esac
done
shift $(($OPTIND-1))


# Linux or OSX
JOPT="-J"
if [ "`uname`" == "Darwin" ] ; then
  JOPT=
fi

# both or neither RELEASE options must be set
BRANCH=test
if [ "$FDS_RELEASE" != "" ]; then
  if [ "$SMV_RELEASE" != "" ]; then
    FDS_RELEASE="-x $FDS_RELEASE"
    SMV_RELEASE="-y $SMV_RELEASE"
    BRANCH="release"
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

# get location of firebot files
FIREBOT_HOME=\~firebot
if [ "$FIREBOT_HOST" == "LOCAL" ]; then
  FIREBOT_HOME=\$HOME/.firebot/pass
fi

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

# update bot and webpages repos
UPDATE_REPO bot      master     || exit 1
UPDATE_REPO webpages nist-pages || exit 1

# get apps and documents
cd $curdir
cd ../Firebot
$ECHO ./run_firebot.sh $FORCE -c -C -B -g $FIREBOT_HOST -G $FIREBOT_HOME $JOPT $FDS_RELEASE $SMV_RELEASE $FIREBOT_BRANCH -T $MAILTO

# generate bundle
cd $curdir
$ECHO ./run_bundlebot.sh $FORCE $BUNDLE_BRANCH -p $FIREBOT_HOST $VERBOSE -w -g
