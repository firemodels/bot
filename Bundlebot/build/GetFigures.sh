#!/bin/bash

CURDIR=`pwd`

cd bundles
BUNDLEDIR=`pwd`

echo ***cleaning $BUNDLEDIR
git clean -dxf

cd $CURDIR

DOWNLOADFILE ()
{
  TAG=$1
  FILE=$2
  echo downloading $FILE
  gh release download $TAG -p $FILE -D $BUNDLEDIR  -R github.com/$GH_OWNER/$GH_REPO
}

DOWNLOADFILE SMOKEVIEW_TEST SMV_UG_figures.tar.gz
DOWNLOADFILE SMOKEVIEW_TEST SMV_VG_figures.tar.gz

DOWNLOADFILE  FDS_TEST FDS_UG_figures.tar.gz
DOWNLOADFILE  FDS_TEST FDS_TG_figures.tar.gz
DOWNLOADFILE  FDS_TEST FDS_VERG_figures.tar.gz
DOWNLOADFILE  FDS_TEST FDS_VALG_figures.tar.gz

echo ***files downloaded to $BUNDLEDIR
cd $CURDIR
exit 0
