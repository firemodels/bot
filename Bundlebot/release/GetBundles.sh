#!/bin/bash

CURDIR=`pwd`
source config.sh

cd bundles
BUNDLEDIR=`pwd`

echo ***cleaning $BUNDLEDIR
git clean -dxf

cd $CURDIR

BUNDLE_BASE=${BUNDLE_FDS_TAG}_${BUNDLE_SMV_TAG}_

DOWNLOADFILE ()
{
  FILE=$1
  echo downloading $FILE
  gh release download $GH_FDS_TAG -p $FILE -D $BUNDLEDIR  -R github.com/$GH_OWNER/$GH_REPO
}

DOWNLOADFILE FDS_Config_Management_Plan.pdf
DOWNLOADFILE FDS_Technical_Reference_Guide.pdf
DOWNLOADFILE FDS_User_Guide.pdf
DOWNLOADFILE FDS_Validation_Guide.pdf
DOWNLOADFILE FDS_Verification_Guide.pdf

DOWNLOADFILE SMV_User_Guide.pdf
DOWNLOADFILE SMV_Verification_Guide.pdf
DOWNLOADFILE SMV_Technical_Reference_Guide.pdf

DOWNLOADFILE ${BUNDLE_BASE}lnx.sh
DOWNLOADFILE ${BUNDLE_BASE}lnx.tar.gz
DOWNLOADFILE ${BUNDLE_BASE}lnx.sha1

DOWNLOADFILE ${BUNDLE_BASE}osx.sh
DOWNLOADFILE ${BUNDLE_BASE}osx.tar.gz
DOWNLOADFILE ${BUNDLE_BASE}osx.sha1

DOWNLOADFILE ${BUNDLE_BASE}win.exe
DOWNLOADFILE ${BUNDLE_BASE}win.zip
DOWNLOADFILE ${BUNDLE_BASE}win.sha1

echo ***files downloaded to $BUNDLEDIR
cd $CURDIR
exit 0
