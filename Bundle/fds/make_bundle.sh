#!/bin/bash
FDSEDITION=FDS6

platform="linux"
if [ "`uname`" == "Darwin" ]; then
  platform="osx"
fi

if [ "$fds_version" == "" ]; then
  fds_version=FDS6.x.y
fi
if [ "$smv_version" == "" ]; then
  smv_version=SMV6.x.y
fi

#---------------------------------------------
#                   usage
#---------------------------------------------

function usage {
echo "Usage:"
echo "make_bundle.sh [options]"
echo ""
echo "Create an installer named ${fds_version}-${smv_version}_${platform}64.sh"
echo "Options:"
echo "-b - only make the bundle script.  Assume that all prerequisites have been"
echo "     generated (fds, smokeview, manuals etc)"
if [ "$platform" == "linux" ]; then
echo "-d  directory - directory where installation is placed [default: \$HOME/FDS/$FDSEDITION]"
else
echo "-d  directory - directory where installation is placed [default: /Applications/FDS/$FDSEDITION]"
fi
echo "-f - fds version [default: $fds_version]"
echo "-h - show this message"
echo "-s - smokeview version [default: $smv_version]"
exit
}

MAKE_BUNDLE_PARTS=1
while getopts 'bd:f:hs:' OPTION
do
case $OPTION in
  b)
  MAKE_BUNDLE_PARTS=
  ;;
  d)
  FDSEDITION=$OPTION
  ;;
  f)
  fds_version=$OPTION
  ;;
  h)
  usage;
  exit
  ;;
  s)
  smv_version=$OPTION
  ;;
esac
done
shift $(($OPTIND-1))

CURDIR=`pwd`
cd $scripts

echo making bundle for $platform

if [ "$MAKE_BUNDLE_PARTS" == "1" ]; then
  echo -------------------------------------------------
  echo -------------building fds------------------------
  echo -------------------------------------------------
  ./make_fds_progs.sh
  ./copy_apps.sh firebot
  echo -------------------------------------------------
  echo --- building smokeview and associated programs --
  echo -------------------------------------------------
  ./make_smv_progs.sh
  ./copy_apps.sh smokebot
  echo -------------------------------------------------
  echo -------getting fds pubs -------------------------
  echo -------------------------------------------------
  ./copy_pubs.sh firebot /home2/smokevis2/firebot blaze.el.nist.gov
  echo -------------------------------------------------
  echo -------getting smokeview pubs -------------------
  echo -------------------------------------------------
  ./copy_pubs.sh firebot /home2/smokevis2/smokebot blaze.el.nist.gov
fi
echo -------------------------------------------------
echo ------- making the bundle script -----------------------
echo -------------------------------------------------
./make_bundle.sh
echo -------------------------------------------------
echo ------- complete --------------------------------
echo -------------------------------------------------

cd $CURDIR
