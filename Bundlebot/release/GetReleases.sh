#!/bin/bash
OWNER=$1

if [ "$OWNER" == "" ]; then
  OWNER=`whoami`
fi

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
  RELEASE=$1
  FILE=$2
  echo downloading $FILE
  gh release download $RELEASE -p $FILE -D $BUNDLEDIR  -R github.com/$OWNER/test_bundles
}

DOWNLOADFILE FDS_TEST FDS_Config_Management_Plan.pdf
DOWNLOADFILE FDS_TEST FDS_Technical_Reference_Guide.pdf
DOWNLOADFILE FDS_TEST FDS_User_Guide.pdf
DOWNLOADFILE FDS_TEST FDS_Validation_Guide.pdf
DOWNLOADFILE FDS_TEST FDS_Verification_Guide.pdf

DOWNLOADFILE SMOKEVIEW_TEST SMV_User_Guide.pdf
DOWNLOADFILE SMOKEVIEW_TEST SMV_Verification_Guide.pdf
DOWNLOADFILE SMOKEVIEW_TEST SMV_Technical_Reference_Guide.pdf

DOWNLOADFILE FDS_TEST ${BUNDLE_BASE}lnx.sh
DOWNLOADFILE FDS_TEST ${BUNDLE_BASE}lnx_manifest.html

DOWNLOADFILE FDS_TEST ${BUNDLE_BASE}osx.sh
DOWNLOADFILE FDS_TEST ${BUNDLE_BASE}osx_manifest.html

DOWNLOADFILE FDS_TEST ${BUNDLE_BASE}win.exe
DOWNLOADFILE FDS_TEST ${BUNDLE_BASE}win_manifest.html

echo ***files downloaded to $BUNDLEDIR
cd $CURDIR
exit 0
