#!/bin/bash

if [ "`uname`" == "Darwin" ] ; then
  LINUX=
  OSX=1
else
  LINUX=1
  OSX=
fi

#---------------------------------------------
#                   usage
#---------------------------------------------

function usage {
echo "This script builds Linux and OSX bundlesa nightly bundle."
echo "This script runs on a Linux computer building the Linux bundle"
echo "there.  The OSX bundle is built by ssh'ing to an OSX computer"
echo "using The environment variables OSX_BUILD_HOST and OSX_BUILD_REPO"
echo "to define the Mac computer and repo root "
echo ""
echo "Options:"
echo "-h - display this message"
exit
}

while getopts 'h' OPTION
do
case $OPTION  in
  h)
   usage;
   ;;
esac
done
shift $(($OPTIND-1))

if [ "$LINUX" == "1" ]; then
  ./make_bundle.sh
fi

if [ "$OSX" == "1" ]; then
  ./make_bundle.sh -u
fi
