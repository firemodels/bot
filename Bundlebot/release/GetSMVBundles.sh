#!/bin/bash

CURDIR=`pwd`
source config.sh

cd smvbundles
BUNDLEDIR=`pwd`

echo ***cleaning $BUNDLEDIR
git clean -dxf

cd $CURDIR

BUNDLE_BASE=${BUNDLE_SMV_TAG}_

DOWNLOADFILE ()
{
  FILE=$1
  echo downloading $FILE
  gh release download SMOKEVIEW_TEST2 -p $FILE -D $BUNDLEDIR  -R github.com/$GH_OWNER/$GH_REPO
}

DOWNLOADFILE ${BUNDLE_BASE}lnx.sh
#DOWNLOADFILE ${BUNDLE_BASE}lnx.tar.gz
DOWNLOADFILE ${BUNDLE_BASE}lnx.sha1

DOWNLOADFILE ${BUNDLE_BASE}osx.sh
#DOWNLOADFILE ${BUNDLE_BASE}osx.tar.gz
DOWNLOADFILE ${BUNDLE_BASE}osx.sha1

DOWNLOADFILE ${BUNDLE_BASE}win.exe
#DOWNLOADFILE ${BUNDLE_BASE}win.zip
DOWNLOADFILE ${BUNDLE_BASE}win.sha1

echo ***files downloaded to $BUNDLEDIR
cd $CURDIR
exit 0
