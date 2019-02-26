#!/bin/bash

#---------------------------------------------
#                   SETENV
#---------------------------------------------

SETENV ()
{
  local var=$1
  local bashvar=$2

  if [ "\$$bashvar" != "" ]; then
    eval $var=\$$bashvar
  fi
}

#---------------------------------------------
#                   DEFAULT
#---------------------------------------------

function DEFAULT {
  arg=$1
  DEF=
  if [ "$arg" != "" ]; then
    DEF="[default: $arg]"
  fi
}


#---------------------------------------------
#                   usage
#---------------------------------------------

usage ()
{
echo "set_firebot_revisions.sh [options]"
echo "   set fds and smv repo revisiokns"
echo ""
echo "Options:"
DEFAULT $bot_host
echo "-b - set hostname where firebot is run $DEF"
DEFAULT $firebot_home
echo "-f - set firebot home directory $DEF"
echo "-h - display this message"
DEFAULT $smokebot_home
echo "-m - set fds and smv repo branches to master"
exit
}

# define variables in startup file if not passed into this script

build_apps=
GET_BOT_REVISION=
set_master=
SETENV bot_host      BOT_HOST
SETENV firebot_home  FIREBOT_HOME
SETENV smokebot_home SMOKEBOT_HOME
SETENV mpi_version   MPI_VERSION

#*** parse command line options

while getopts 'b:f:hm' OPTION
do
case $OPTION  in
  b)
   bot_host=$OPTARG
   ;;
  f)
   firebot_home=$OPTARG
   ;;
  h)
   usage
   ;;
  m)
   set_master=1
   ;;
esac
done
shift $(($OPTIND-1))

curdir=`pwd`
cd ../../../..
repo_root=`pwd`

if [ "$set_master" == "1" ]; then
  echo "setting branch in fds repo to master"
  cd $repo_root/fds
  git checkout master >& /dev/null
  
  echo "setting branch in smv repo to master"
  cd $repo_root/smv
  git checkout master >& /dev/null

  cd $curdir
  exit 0
fi

SMV_REVISION=
FDS_REVISION=

if [ "$bot_host" == "" ]; then
  echo "***error: bot_host is not defined:"
  exit 1
fi

if [ "$firebot_home" == "" ]; then
  echo "***error: firebot_home is not dehind"
  exit 1
fi

if [ "$smokebot_home" == "" ]; then
  echo "***error: smokebot_home is not defined"
  exit 1
fi

rm -f fds_hash
scp -q $bot_host\:$firebot_home/.firebot/history/fds_hash fds_hash
if [ ! -e fds_hash ]; then
  echo "***error: fds_hash was not copied from"
  echo "          $firebot_home/.firebot/history on $bot_host"
  exit 1
fi
fds_hash=`head -1 fds_hash`

rm -f smv_hash
scp -q $bot_host\:$firebot_home/.firebot/history/smv_hash smv_hash
if [ ! -e smv_hash ]; then
  echo "***error: smv_hash was not copied from"
  echo "          $firebot_home/.firebot/history on $bot_host"
  exit 1
fi
smv_hash=`head -1 smv_hash`

echo "setting branch in fds repo to $fds_hash"
cd $repo_root/fds
git checkout $fds_hash >& /dev/null
  
echo "setting branch in smv repo to $smv_hash"
cd $repo_root/smv
git checkout $smv_hash >& /dev/null

cd $curdir
exit 0
