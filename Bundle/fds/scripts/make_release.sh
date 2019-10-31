#!/bin/bash

#---------------------------------------------
#                   usage
#---------------------------------------------

function usage {
echo "This script builds a nightly bundle"
echo ""
echo "Options:"
echo "-h - display this message"
exit
}

#define default home directories for apps and pubs
app_home=\~firebot
fds_pub_home=\~firebot
smv_pub_home=\~smokebot

LINUX=1
OSX=

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
  ./make_bundle.sh -B
fi
