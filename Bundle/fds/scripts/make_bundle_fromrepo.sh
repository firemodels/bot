#!/bin/bash

#---------------------------------------------
#                   usage
#---------------------------------------------

function usage {
option=$1
echo "Script used to build a bundle from current revision of the fds and smv repos"
echo "example usage:"
echo "1.  on blaze using firebot and smokebot accounts"
echo "./make_bundle_fromrepos.sh "
echo ""
echo "2. on floga using user account for apps and blaze for pubs"
echo "./make_bundlefromrepos.sh -U -p blaze.el.nist.gov -F ~firebot -S ~smokebot"
echo ""
echo "Options:"
echo "-f - home directory containing fds apps [default: $firebot_app_home]"
echo "-F - home directory containing fds pubs [default: $firebot_pub_home]"
echo "-h - display this message"
echo "-p - host containing pubs"
echo "-s - home directory containing smv apps [default: $smokebot_app_home]"
echo "-S - home directory containing smv pubs [default: $smokebot_pub_home]"
echo "-u - home directory containing apps and pubs is $HOME"
echo "     host containing apps and pubs is `hostname`"
echo "-U - home directory containing apps is $HOME"
echo "-v - show parameters used to build bundle"
exit
}

firebot_app_home=~firebot
smokebot_app_home=~smokebot

smokebot_pub_home=~smokebot
firebot_pub_home=~firebot
pub_host=`hostname`
showparms=


while getopts 'f:F:hp:s:S:uUv' OPTION
do
case $OPTION  in
  f)
   firebot_app_home=$OPTARG
   ;;
  F)
   firebot_pub_home=$OPTARG
   ;;
  h)
   usage;
   ;;
  p)
   pub_host=$OPTARG
   ;;
  s)
   smokebot_app_home=$OPTARG
   ;;
  S)
   smokebot_pub_home=$OPTARG
   ;;
  u)
   firebot_app_home=$HOME
   smokebot_app_home=$HOME
   firebot_pub_home=$HOME
   smokebot_pub_home=$HOME
   pub_host=`hostname`
   ;;
  U)
   firebot_app_home=$HOME
   smokebot_app_home=$HOME
   ;;
  v)
   showparms=1
   ;;
esac
done
shift $(($OPTIND-1))

#*** Linux parameters

intel_mpi_version_linux=19u4
mpi_version_linux=INTEL

#*** OSX parameters

intel_mpi_version_osx=19u4
mpi_version_osx=3.1.2

# determine platform script is running on

if [ "`uname`" == "Darwin" ]; then
  intel_mpi_version=$intel_mpi_version_osx
  mpi_version=$mpi_version_osx
else
  intel_mpi_version=$intel_mpi_version_linux
  mpi_version=$mpi_version_linux
fi

if [ "$showparms" == "1" ]; then
  echo firebot_app_home=$firebot_app_home
  echo smokebot_app_home=$smokebot_app_home

  echo smokebot_pub_home=$smokebot_pub_home
  echo firebot_pub_home=$firebot_pub_home
  echo pub_host=$pub_host`

  echo intel_mpi_version=$intel_mpi_version
  echo mpi_version=$mpi_version
  exit
fi

./copy_pubs.sh firebot  $firebot_pub_home/.firebot/pubs   $pub_host
./copy_pubs.sh smokebot $smokebot_pub_home/.smokebot/pubs $pub_host

./copy_apps.sh firebot  $firebot_app_home/.firebot/fds
./copy_apps.sh smokebot $smokebot_app_home/.smokebot/smv 

export NOPAUSE=1
args=$0
DIR=$(dirname "${args}")
cd $DIR
DIR=`pwd`

# get fds repo revision
cd $DIR
fdsrepo=../../../../fds
cd $fdsrepo
FDSREV=`git describe --abbrev | awk -F '-' '{print $1"-"$2}'`

# get smv repo revision
cd $DIR
smvrepo=../../../../smv
cd $smvrepo
SMVREV=`git describe --abbrev | awk -F '-' '{print $1"-"$2}'`

cd $DIR
echo ./bundle_generic.sh $FDSREV $SMVREV $mpi_version $intel_mpi_version
./bundle_generic.sh $FDSREV $SMVREV $mpi_version $intel_mpi_version
