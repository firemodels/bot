#!/bin/bash
type=$1

if [ "$type" == "smv" ]; then
  GH_TAG=$GH_SMV_TAG
  FIG_TYPE=Smokeview
else
  GH_TAG=$GH_FDS_TAG
  FIG_TYPE=FDS
fi

echo ""
echo ***copying $FIG_TYPE figures from github.com/$GH_OWNER/$GH_REPO using tag: $GH_TAG
gh release download $GH_TAG -p '*figures.tar.gz' -R github.com/$GH_OWNER/$GH_REPO --clobber

