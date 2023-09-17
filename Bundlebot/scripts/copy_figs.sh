#!/bin/bash
type=$1

if [ "$type" == "smokeview" ]; then
  GH_TAG=$GH_SMOKEVIEW_TAG
  FIG_TYPE=Smokeview
else
  GH_TAG=$GH_FDS_TAG
  FIG_TYPE=FDS
fi

echo ""
echo gh release download $GH_TAG -p '*figures.tar.gz' -R github.com/$GH_OWNER/$GH_REPO --clobber
gh release download $GH_TAG -p '*figures.tar.gz' -R github.com/$GH_OWNER/$GH_REPO --clobber

