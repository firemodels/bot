#!/bin/bash

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
echo "-l - build only the Linux bundle"
echo "-o - build only the OSX bundle"
exit
}

#define default home directories for apps and pubs
app_home=\~firebot
fds_pub_home=\~firebot
smv_pub_home=\~smokebot

LINUX=1
OSX=1

while getopts 'hlo' OPTION
do
case $OPTION  in
  h)
   usage;
   ;;
  l)
   LINUX=1
   OSX=
   ;;
  o)
   LINUX=
   OSX=1
   ;;
esac
done
shift $(($OPTIND-1))

if [ "$LINUX" == "1" ]; then
  ./make_bundle.sh
fi

if [ "$OSX" == "o" ]; then
  if [ "$OSX_BUILD_HOST" != "" ]; then
    if [ "$OSX_BUILD_REPO" != "" ]; then
      ./make_bundle.sh -B
      ssh -q $$OSX_BUIILD_HOST \( cd \~/$$OSX_BUILD_REPO/bot/Bundle/fds/scripts \; ./make_bundle.sh -B  \)
    fi
  fi
fi
