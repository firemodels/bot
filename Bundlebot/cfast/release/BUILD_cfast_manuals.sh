#!/bin/bash
CURDIR=`pwd`
CONFIG=$CURDIR/config.sh
cd ../../../Cfastbot
echo ./run_cfastbot.sh -q firebot -U -F $CONFIG
./run_cfastbot.sh -f -c -b -q firebot -U -F $CONFIG
