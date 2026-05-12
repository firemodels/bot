#!/bin/bash

bundles=$HOME/.bundle/bundles
if [ -e $bundles ]; then
  rm -rf $bundles
  echo cleaning $bundles on `hostname`
  mkdir $bundles
else
 echo ***error: directory $bundles does not exist
 mkdir -p $bundles
fi
