#!/bin/bash

gh release download $GH_SMOKEVIEW_TAG -p SMV_INFO.txt -R github.com/$GH_OWNER/$GH_REPO -D output --clobber
grep SMV_HASH     output/SMV_INFO.txt | awk '{print $2}' > output/SMV_HASH
grep SMV_REVISION output/SMV_INFO.txt | awk '{print $2}' > output/SMV_REVISION
