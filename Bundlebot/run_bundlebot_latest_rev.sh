#!/bin/bash

CONFIG=$HOME/.bundle/bundle_config
echo "testing bundle scripts - building test bunde"
if [ -e $CONFIG ]; then
  source  $CONFIG
  if [ "$bundle_hostname" != "" ]; then
    ./run_bundlebot.sh -f -H $bundle_hostname -L -U
  else
    echo "***error: bundle_hostname is not defined"
  fi
else
  echo "***error: $CONFIG does not exist"
fi
