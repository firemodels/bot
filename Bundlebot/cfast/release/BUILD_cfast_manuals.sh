#!/bin/bash
LOCAL_OWNER=$1
if [ "$LOCAL_OWNER" != "" ]; then
  LOCAL_OWNER="-o $LOCAL_OWNER"
fi
CURDIR=`pwd`
CONFIG=$CURDIR/config.sh
cd ../../../Cfastbot
git clean -dxf >& /dev/null
./run_cfastbot.sh -f -c -b -q firebot $LOCAL_OWNER -U -F $CONFIG
