#!/bin/bash
option=$1

if [ "$option" != "nightly" ]; then
  APPOWNER=`whoami`
else
  APPOWNER=firemodels
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
  OWNER=$1
  FILE=$2
  echo downloading $FILE
  gh release download FDS_TEST -p $FILE -D $BUNDLEDIR  -R github.com/$OWNER/test_bundles
}

DOWNLOADFILE firemodels FDS_Config_Management_Plan.pdf
DOWNLOADFILE firemodels FDS_Technical_Reference_Guide.pdf
DOWNLOADFILE firemodels FDS_User_Guide.pdf
DOWNLOADFILE firemodels FDS_Validation_Guide.pdf
DOWNLOADFILE firemodels FDS_Verification_Guide.pdf

DOWNLOADFILE firemodels SMV_User_Guide.pdf
DOWNLOADFILE firemodels SMV_Verification_Guide.pdf
DOWNLOADFILE firemodels SMV_Technical_Reference_Guide.pdf

DOWNLOADFILE $APPOWNER ${BUNDLE_BASE}lnx.sh
DOWNLOADFILE $APPOWNER ${BUNDLE_BASE}lnx.tar.gz
DOWNLOADFILE $APPOWNER ${BUNDLE_BASE}lnx.sha1

DOWNLOADFILE $APPOWNER ${BUNDLE_BASE}osx.sh
DOWNLOADFILE $APPOWNER ${BUNDLE_BASE}osx.tar.gz
DOWNLOADFILE $APPOWNER ${BUNDLE_BASE}osx.sha1

DOWNLOADFILE $APPOWNER ${BUNDLE_BASE}win.exe
DOWNLOADFILE $APPOWNER ${BUNDLE_BASE}win.zip
DOWNLOADFILE $APPOWNER ${BUNDLE_BASE}win.sha1

echo ***files downloaded to $BUNDLEDIR
cd $CURDIR
exit 0
