#!/bin/bash

#*** Linux parameters

intel_mpi_version_linux=19u4
mpi_version_linux=INTEL

#*** OSX parameters

intel_mpi_version_osx=19u4
mpi_version_osx=3.1.2

#---------------------------------------------
#                   usage
#---------------------------------------------

function usage {
echo "Script used to build a bundle from the current revision of the fds and"
echo "smv repos. By default, this script uses apps built by the firebot account"
echo "and pubs built by the firebot and smokebot accounts on this computer."
echo ""
echo "example usage:"
echo "1. firebot and smokebot accounts on this computer for pubs and apps"
echo "./make_bundle.sh "
echo ""
echo "2. remote firebot and smokebot accounts (say xxx.yyy.zzz) for pubs"
echo "   and user firebot account for apps"
echo "./make_bundle.sh -u -p xxx.yyy.zzz"
echo ""
echo "Environment variable:"
echo "PBS_HOME - host used to build pubs"
echo ""
echo "Options:"
echo "-B - build apps - this script runs firebot with the -B option"
echo "-f - home directory containing apps [default: $app_home]"
echo "-F - home directory containing fds pubs [default: $fds_pub_home]"
echo "-S - home directory containing smokeview pubs [default: $smv_pub_home]"
echo "-h - display this message"
echo "-p - host containing pubs [default: $pub_host]"
echo "-u - use apps built by firebot in the `whoami` account"
echo "-U - use apps built by firebot and pubs built by firebot"
echo "     and smokebot in the `whoami` account"
echo "-v - show parameters used to build bundle (bundle not generated)"
exit
}

app_home=\~firebot
fds_pub_home=\~firebot
smv_pub_home=\~smokebot
pub_host=`hostname`
if [ "$PUB_HOST" != "" ]; then
  pub_host=$PUB_HOST
fi
showparms=
ECHO=
BUILD_APPS=

while getopts 'Bf:F:hp:S:uUv' OPTION
do
case $OPTION  in
  B)
   BUILD_APPS=1
   app_home=$HOME
   ;;
  f)
   app_home=$OPTARG
   ;;
  F)
   fds_pub_home=$OPTARG
   ;;
  h)
   usage;
   ;;
  p)
   pub_host=$OPTARG
   ;;
  S)
   smv_pub_home=$OPTARG
   ;;
  u)
   app_home=$HOME
   ;;
  U)
   app_home=$HOME
   fds_pub_home=$HOME
   smv_pub_home=$HOME
   ;;
  v)
   showparms=1
   ECHO=echo
   ;;
esac
done
shift $(($OPTIND-1))

# determine platform script is running on

if [ "`uname`" == "Darwin" ]; then
  intel_mpi_version=$intel_mpi_version_osx
  mpi_version=$mpi_version_osx
else
  intel_mpi_version=$intel_mpi_version_linux
  mpi_version=$mpi_version_linux
fi

if [ "$showparms" == "1" ]; then
  echo ""
  echo " Parameters"
  echo " ----------"
  if [ "$BUILD_APPS" == "1" ]; then
    echo "    build apps: yes"
  else
    echo "    build apps: no"
  fi
  echo "   MPI version: $mpi_version"
  echo " Intel version: $intel_mpi_version"
  echo ""
  echo " Home directories"
  echo " ----------------"
  echo " fds/smv apps: $app_home"
  if [ "$pub_host" != `hostname` ]; then
    hostlabel="host: $pub_host"
  else
    hostlabel=
  fi
  echo "     fds pubs: $fds_pub_home $hostlabel"
  echo "     smv pubs: $smv_pub_home $hostlabel"
  echo ""
fi

export NOPAUSE=1
args=$0
DIR=$(dirname "${args}")
cd $DIR
DIR=`pwd`

if [ "$showparms" == "" ]; then
if [ "$BUILD_APPS" == "1" ]; then
  cd ../../../Firebot
  ./run_firebot.sh -B
  cd $DIR
fi
fi

if [ "$showparms" == "" ]; then
  ./copy_pubs.sh fds $fds_pub_home/.firebot/pubs  $pub_host
  ./copy_pubs.sh smv $smv_pub_home/.smokebot/pubs $pub_host

  ./copy_apps.sh fds $app_home/.firebot/fds
  ./copy_apps.sh smv $app_home/.firebot/smv 
fi

# get fds repo revision
cd $DIR
fdsrepo=../../../../fds
cd $fdsrepo
SUBREV=`git describe --abbrev | awk -F '-' '{print $2}'`
if [ "$SUBREV" == "" ]; then
  FDSREV=`git describe --abbrev | awk -F '-' '{print $1"-0"}'`
else
  FDSREV=`git describe --abbrev | awk -F '-' '{print $1"-"$2}'`
fi

# get smv repo revision
cd $DIR
smvrepo=../../../../smv
cd $smvrepo
SUBREV=`git describe --abbrev | awk -F '-' '{print $2}'`
if [ "$SUBREV" == "" ]; then
  SMVREV=`git describe --abbrev | awk -F '-' '{print $1"-0"}'`
else
  SMVREV=`git describe --abbrev | awk -F '-' '{print $1"-"$2}'`
fi

cd $DIR
if [ "$ECHO" != "" ]; then
  echo " Bundle command"
  echo " --------------"
fi
$ECHO ./bundle_generic.sh $FDSREV $SMVREV $mpi_version $intel_mpi_version
