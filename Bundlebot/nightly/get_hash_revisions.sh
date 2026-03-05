#!/bin/bash
outputdir=$1
USE_CURRENT=$2

if [ "$outputdir" == "" ]; then
  outputdir=output
fi

if [ "$USE_CURRENT" == "" ]; then
  gh release download SMOKEVIEW_TEST -p SMV_INFO.txt -R github.com/firemodels/test_bundles -D $outputdir --clobber
else
  ./make_info.sh > $outputdir/SMV_INFO.txt
fi
grep SMV_HASH     $outputdir/SMV_INFO.txt | awk '{print $2}' > $outputdir/SMV_HASH
grep SMV_REVISION $outputdir/SMV_INFO.txt | awk '{print $2}' > $outputdir/SMV_REVISION
