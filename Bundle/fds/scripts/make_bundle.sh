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
echo "The script build a bundle using apps built by firebot, fds pubs built by"
echo "firebot, smokeview pubs built by smokebot and other files found in the"
echo "fds, smv and botrepos"
echo ""
echo "Example usage:"
echo "1. apps built by firebot, pubs built by firebot/smokebot both on the computer `hostname`".
echo "   Thhis is how NIST builds Linux bundles."
echo "./make_bundle.sh "
echo ""
echo "2. apps built by firebot on `hostname`, pubs built by firebot/smokebot on the computer xxx.yyy.zzz"
echo "   This is how NIST builds OSX bundles."
echo "./make_bundle.sh -u -p xxx.yyy.zzz"
echo ""
echo "The -v option may be used to show the parameters to build the bundle"
echo "The following environment variables may be used to set the host names used to build apps and pubs"
echo ""
echo "APP_HOST - host where apps are located"
echo "PBS_HOST - host where pubs are located"
echo ""
echo "Options:"
echo "-a - host containing apps [default: $app_host]"
echo "-B - build apps - this script builds apps by running"
echo "     firebot with the -B option"
echo "-d - directory where created bundle is put [default: $bundle_dir]"
echo "-f - home directory containing apps [default: $app_home]"
echo "-F - home directory containing fds pubs [default: $fds_pub_home]"
echo "-S - home directory containing smokeview pubs [default: $smv_pub_home]"
echo "-h - display this message"
echo "-p - host containing pubs [default: $pub_host]"
echo "-u - use apps built by the `whoami` firebot account"
echo "-U - use apps built by the `whoami` firebot account and pubs built "
echo "     by the `whoami` firebot and smokebot accounts"
echo "-v - show parameters used to build bundle (the bundle not generated)"
exit
}

#define default home directories for apps and pubs
app_home=\~firebot
fds_pub_home=\~firebot
smv_pub_home=\~smokebot

# define default host where pubs are found
pub_host=`hostname`
if [ "$PUB_HOST" != "" ]; then
  pub_host=$PUB_HOST
fi

# define default host where apps are found
app_host=`hostname`
if [ "$APP_HOST" != "" ]; then
  app_host=$APP_HOST
fi

showparms=
ECHO=
BUILD_APPS=
bundle_dir=$HOME/.bundle/bundles

while getopts 'Bd:f:F:hp:S:uUv' OPTION
do
case $OPTION  in
  B)
   BUILD_APPS=1
   app_home=$HOME
   ;;
  d)
   bundle_dir=$HOME
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
  platform=osx64
else
  intel_mpi_version=$intel_mpi_version_linux
  mpi_version=$mpi_version_linux
  platform=linux64
fi

if [ "$showparms" == "1" ]; then
  echo ""
  echo " Parameters"
  echo " ----------"
  if [ "$BUILD_APPS" == "1" ]; then
    echo "            build apps: yes"
  else
    echo "            build apps: no"
  fi
  echo "           MPI version: $mpi_version"
  echo "         Intel version: $intel_mpi_version"
  if [ "$app_host" != `hostname` ]; then
    hostlabel="on $app_host"
  else
    hostlabel="on this computer"
  fi
  echo " fds/smv app directory: $app_home/.firebot/fds $hostlabel"
  if [ "$pub_host" != `hostname` ]; then
    hostlabel="on $pub_host"
  else
    hostlabel="on this computer"
  fi
  echo "     fds pub directory: $fds_pub_home/.firebot/pubs $hostlabel"
  echo "     smv pub directory: $smv_pub_home/.smokebot/pubs $hostlabel"
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

  ./copy_apps.sh fds $app_home/.firebot/fds       $app_host
  ./copy_apps.sh smv $app_home/.firebot/smv       $app_host
fi

# get fds and smv repo revision used to build apps

if [ -e $HOME/.bundle/fds/FDS_REVISION ]; then
  FDSREV=`cat $HOME/.bundle/fds/FDS_REVISION`
else
  FDSREV=fdstest
fi
if [ -e $HOME/.bundle/smv/SMV_REVISION ]; then
  SMVREV=`cat $HOME/.bundle/smv/SMV_REVISION`
else
  SMVREV=smvtest
fi

if [ "$ECHO" != "" ]; then
  echo " Bundle command"
  echo " --------------"
fi
cd $DIR
$ECHO ./bundle_generic.sh $FDSREV $SMVREV $mpi_version $intel_mpi_version $bundle_dir
if [ "$ECHO" == "" ]; then
  installer_base=${FDSREV}-${SMVREV}_$platform
  rm -f $bundle_dir/${installer_base}.tar.gz
  rm -rf $bundle_dir/${installer_base}
fi
