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
echo "This script builds a bundle using apps built by firebot,"
echo "FDS pubs built by firebot, Smokeview pubs built by smokebot"
echo "and other files found in the fds, smv and bot repos."
echo ""
echo "Example usage:"
echo "1. apps built by firebot and FDS/Smokeview pubs built by"
echo "   firebot/smokebot on the computer runneng this script."
echo "   This is how NIST build Linux bundles"
echo ""
echo "./make_bundle.sh "
echo ""
echo "2. apps built by firebot on this computer, pubs built by"
echo "   firebot/smokebot on the computer xxx.yyy.zzz. This is how"
echo "   NIST builds OSX bundles where 'this computer' is an OSX"
echo "   computer and xxx.yyy.zzz is a Linux computer that ran firebot."
echo ""
echo "./make_bundle.sh -u -p xxx.yyy.zzz"
echo ""
echo "The -v option may be used to show the parameters used to"
echo "build the bundle."
echo ""
echo "The following environment variables may be used to set the"
echo "host names used to build apps and pubs."
echo ""
echo "APP_HOST    - host where apps are located"
echo "PBS_HOST    - host where pubs are located"
echo "UPLOAD_HOST - host where installer is uploaded to Google Drive"
echo ""
echo "Options:"
echo "-a - host containing apps [default: $app_host]"
echo "-A - home directory containing FDS pubs [default: $fds_pub_home]"
echo "-B - build apps - this script builds apps by running"
echo "     firebot with the -B option"
echo "-c - use apps and pubs previously copied to $HOME/.bundle/apps"
echo "     and $HOME/.bundle/pubs"
echo "-d - bundle directory location [default: $bundle_dir]"
echo "-f - force this script to run"
echo "-F - home directory containing apps [default: $app_home]"
echo "-g - upload installer file to a google drive directory with id in the"
echo "     file $HOME/.bundle/GOOGLE_DIR_ID"
echo "-S - home directory containing Smokeview pubs [default: $smv_pub_home]"
echo "-h - display this message"
echo "-p - host containing pubs [default: $pub_host]"
echo "-u - use apps built by firebot in the `whoami` account"
echo "-U - use apps built by firebot and pubs built firebot and smokebot"
echo "     both in the `whoami` account"
echo "-v - show parameters used to build bundle (the bundle is not generated)"
echo "-w - overwrite bundle (it it already exists)"
exit 0
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
USE_CACHE=
OVERWRITE=
UPLOAD_GOOGLE=
FORCE=
GOOGLE_DIR_ID_FILE=$HOME/.bundle/GOOGLE_DIR_ID

while getopts 'A:Bcd:fF:ghp:S:uUvw' OPTION
do
case $OPTION  in
  A)
   app_home=$OPTARG
   ;;
  B)
   BUILD_APPS=1
   app_home=$HOME
   ;;
  d)
   bundle_dir=$HOME
   ;;
  c)
   USE_CACHE=1
   BUILD_APPS=
   app_home=$HOME
   pub_host=`hostname`
   fds_pub_home=$HOME
   smv_pub_home=$HOME
   ;;
  f)
   FORCE="1"
   ;;
  F)
   fds_pub_home=$OPTARG
   ;;
  g)
   UPLOAD_GOOGLE=1
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
  w)
   OVERWRITE=1
   ;;
esac
done
shift $(($OPTIND-1))

# prevent more than one instance of the make_bundle.sh script from running
# at the same time

LOCK_FILE=$HOME/.bundle/make_bundle_lock
if [ "$FORCE" == "" ]; then
if [ -e $LOCK_FILE ]; then
  echo "***error: another instance of the make_bundle script is apparently running."
  echo "          If this is not the case re-run using the -f option."
  exit 1
fi
fi
touch $LOCK_FILE

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
    echo "               build apps: yes"
  else
    echo "               build apps: no"
  fi
  echo "              MPI version: $mpi_version"
  echo "            Intel version: $intel_mpi_version"
  if [ "$app_host" != `hostname` ]; then
    hostlabel="on $app_host"
  else
    hostlabel="on this computer"
  fi
  if [ "$USE_CACHE" == "1" ]; then
    APPDIR=.bundle
    FDS_PUBDIR=.bundle
    SMV_PUBDIR=.bundle
  else
    APPDIR=.firebot
    FDS_PUBDIR=.firebot
    SMV_PUBDIR=.smokebot
  fi
  echo "    fds/smv app directory: $app_home/$APPDIR/apps $hostlabel"
  hostlabel="on this computer"
  if [ "$pub_host" != `hostname` ]; then
    hostlabel="on $pub_host"
  fi
  if [ "$USE_CACHE" == "1" ]; then
    echo "    fds/smv pub directory: $fds_pub_home/$FDS_PUBDIR/pubs $hostlabel"
  else
    echo "        fds pub directory: $fds_pub_home/$FDS_PUBDIR/pubs $hostlabel"
    echo "        smv pub directory: $smv_pub_home/$SMV_PUBDIR/pubs $hostlabel"
  fi
    echo "         bundle directory: $bundle_dir"
  if [ "$UPLOAD_GOOGLE" == "1" ]; then
    if [ -e $GOOGLE_DIR_ID_FILE ]; then
    echo "Google Drive directory ID: `cat $GOOGLE_DIR_ID_FILE`"
    else
    echo "***warning: Google Drive directory ID file, $GOOGLE_DIR_ID_FILE, does not exist"
    fi
  fi
    if [ "$OVERWRITE" == "1" ]; then
      echo "         overwrite bundle: yes"
    else
      echo "         overwrite bundle: no"
    fi
  echo ""
GOOGLE_DIR_ID_FILE=$HOME/.bundle/GOOGLE_DIR_ID
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
  return_status=$?
  if [ "$return_status" == "1" ]; then
    exit 1
    rm -f $LOCK_FILE
  fi
  cd $DIR
fi
fi

return_code=0
if [ "$USE_CACHE" == "" ]; then
if [ "$showparms" == "" ]; then
  error_log=/tmp/error_log.$$
  rm -f $HOME/.bundle/pubs/*
  ./copy_pubs.sh fds $fds_pub_home/.firebot/pubs  $pub_host $error_log || return_code=1
  ./copy_pubs.sh smv $smv_pub_home/.smokebot/pubs $pub_host $error_log || return_code=1

  rm -f $HOME/.bundle/apps/*
  ./copy_apps.sh fds $app_home/.firebot/apps      $app_host $error_log || return_code=1
  ./copy_apps.sh smv $app_home/.firebot/apps      $app_host $error_log || return_code=1
 
  if [ "$return_code" == "1" ]; then
    cat $error_log
    echo ""
    echo "bundle generation aborted"
    rm $error_log
    rm -f $LOCK_FILE
    exit 1
  fi
fi
fi

# get fds and smv repo revision used to build apps

if [ -e $HOME/.bundle/apps/FDS_REVISION ]; then
  FDSREV=`cat $HOME/.bundle/apps/FDS_REVISION`
else
  FDSREV=fdstest
fi
if [ -e $HOME/.bundle/apps/SMV_REVISION ]; then
  SMVREV=`cat $HOME/.bundle/apps/SMV_REVISION`
else
  SMVREV=smvtest
fi
installer_base=${FDSREV}_${SMVREV}
installer_base_platform=${FDSREV}_${SMVREV}_$platform
if [ "$showparms" == "" ]; then
if [ "$OVERWRITE" == "" ]; then
  installer_file=$bundle_dir/${installer_base_platform}.sh
  if [ -e $installer_file ]; then
    echo "***warning: the installer file $installer_file exists."
    echo "             Use the -w option to overwrite it."
    rm -f $LOCK_FILE
    exit 1
  fi
fi
fi

cd $DIR
if [ "$showparms" == "" ]; then
  $ECHO ./bundle_generic.sh $FDSREV $SMVREV $mpi_version $intel_mpi_version $bundle_dir
  if [ "$UPLOAD_GOOGLE" == "1" ]; then
    if [ -e $HOME/.bundle/$GOOGLE_DIR_ID ]; then
      if [ "$platform" == "linux64" ]; then
        ./upload_bundle.sh $bundle_dir $installer_base $platform 
      else
        ./ssh_upload_bundle.sh $installer_base
      fi
    else
      echo "***warning: the file $HOME/.bundle/GOOGLE_DIR_ID containing the"
      echo "            google drive upload directory ID does not exist."
      echo "            Upload to google drive aborted"
    fi
  fi
fi
if [ "$ECHO" == "" ]; then
  rm -f $bundle_dir/${installer_base_platform}.tar.gz
  rm -rf $bundle_dir/${installer_base_platform}
fi
rm -f $LOCK_FILE
exit 0
