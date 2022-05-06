#!/bin/bash

CONFIG=$HOME/.bundle/bundle_config.sh
echo "testing bundle scripts - building test bunde"
if [ ! -e $CONFIG ]; then
  echo "***error: $CONFIG does not exist"
fi
source  $CONFIG
if [ "$bundle_hostname" == "" ]; then
    echo "***error: bundle_hostname is not defined"
    echo "          deine in $CONFIG"
fi
./run_bundlebot.sh -c -f -H $bundle_hostname -L -U
