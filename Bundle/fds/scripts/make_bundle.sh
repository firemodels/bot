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
echo "Script used to build a bundle from current revision of the fds and smv repos"
echo "example usage:"
echo "1.  on blaze using firebot and smokebot accounts"
echo "./make_bundle.sh "
echo ""
echo "2. on floga using user account for apps and blaze for pubs"
echo "./make_bundle.sh -f $HOME -p blaze.el.nist.gov"
echo ""
echo "Options:"
echo "-b - use bots (firebot and smokebot) for apps and pubs to build bundle"
echo "-f - home directory containing fds and smokeview apps [default: $app_home]"
echo "-F - home directory containing fds pubs [default: $fds_pub_home]"
echo "-S - home directory containing smokeview pubs [default: $smv_pub_home]"
echo "-h - display this message"
echo "-p - host containing pubs"
echo "-v - show parameters used to build bundle"
exit
}

app_home=\~firebot
fds_pub_home=\~firebot
smv_pub_home=\~smokebot
pub_host=`hostname`
showparms=
ECHO=
bots=

while getopts 'bf:F:hp:S:uv' OPTION
do
case $OPTION  in
  b)
   app_home=\~firebot
   fds_pub_home=\~firebot
   smv_pub_home=\~smokebot
   bots=1
   ;;
  f)
   if [ "$bots" == "" ]; then
     app_home=$OPTARG
   fi
   ;;
  F)
   if [ "$bots" == "" ]; then
     fds_pub_home=$OPTARG
   fi
   ;;
  h)
   usage;
   ;;
  p)
   pub_host=$OPTARG
   ;;
  S)
   if [ "$bots" == "" ]; then
     smv_pub_home=$OPTARG
   fi
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
  echo "app_home=$app_home"
  echo "fds_pub_home=$fds_pub_home"
  echo "smv_pub_home=$smv_pub_home"
  echo "pub_host=$pub_host"
  echo "intel_mpi_version=$intel_mpi_version"
  echo "mpi_version=$mpi_version"
fi

if [ "$showparms" == "" ]; then
  ./copy_pubs.sh fds $fds_pub_home/.firebot/pubs  $pub_host
  ./copy_pubs.sh smv $smv_pub_home/.smokebot/pubs $pub_host

  ./copy_apps.sh fds $app_home/.firebot/fds
  ./copy_apps.sh smv $app_home/.firebot/smv 
fi

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
$ECHO ./bundle_generic.sh $FDSREV $SMVREV $mpi_version $intel_mpi_version
