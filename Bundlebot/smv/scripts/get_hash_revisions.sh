#!/bin/bash

gh release download SMOKEVIEW_TEST -p SMV_INFO.txt -R github.com/firemodels/test_bundles -D output --clobber
grep SMV_HASH     output/SMV_INFO.txt | awk '{print $2}' > output/SMV_HASH
grep SMV_REVISION output/SMV_INFO.txt | awk '{print $2}' > output/SMV_REVISION
