#!/bin/bash
FIREBOT_HOST=$1
MAILTO=$2

if [ "$FIREBOT_HOST" == "" ]; then
  exit 1
fi
if [ "$MAILTO" == "" ]; then
  exit 1
fi

curdir=`pwd`

cd ../../../Firebot
./run_firebot.sh -c -B -g $FIREBOT_HOST -G \~firebot -J -R test -T -m $MAILTO

cd $curdir
./run_bundler.sh -u -p $FIREBOT_HOST -w -t -g
