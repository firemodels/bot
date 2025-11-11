#!/bin/bash
output=$1
SMV_HASH=$2
SMV_REVISION=$3

if [ "$output" == "" ]; then
  output=output
fi

if [ "$SMV_HASH" == "" ]; then
  gh release download SMOKEVIEW_TEST -p SMV_INFO.txt -R github.com/firemodels/test_bundles -D $output --clobber
  grep SMV_HASH     $output/SMV_INFO.txt | awk '{print $2}' > $output/SMV_HASH
  grep SMV_REVISION $output/SMV_INFO.txt | awk '{print $2}' > $output/SMV_REVISION
else
  echo $SMV_HASH     > $output/SMV_HASH
  echo $SMV_REVISION > $output/SMV_REVISION
fi
