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

COPYFILES ()
{
  TODIR=$1
  FILE=$2
  if [ -d $TODIR ]; then
    echo "*** untarring $FILE to $TODIR"
    cd $TODIR
    if [ -e $BUNDLEDIR/$FILE ]; then
      tar xf $BUNDLEDIR/$FILE > /dev/null 2>&1
    else
      echo "***error: $BUNDLEDIR/$FILE does not exist"
    fi
  else
    echo ***error: $TODIR does not exist
  fi
}

DOWNLOADFILE SMOKEVIEW_TEST SMV_UG_figures.tar.gz
DOWNLOADFILE SMOKEVIEW_TEST SMV_VG_figures.tar.gz

SMVREPO=../../../smv
cd $SMVREPO
SMVREPO=`pwd`
cd $CURDIR

COPYFILES $SMVREPO//Manuals/SMV_User_Guide/SCRIPT_FIGURES        SMV_UG_figures.tar.gz
COPYFILES $SMVREPO/Manuals/SMV_Verification_Guide/SCRIPT_FIGURES SMV_VG_figures.tar.gz

DOWNLOADFILE  FDS_TEST FDS_UG_figures.tar.gz
DOWNLOADFILE  FDS_TEST FDS_TG_figures.tar.gz
DOWNLOADFILE  FDS_TEST FDS_VERG_figures.tar.gz
DOWNLOADFILE  FDS_TEST FDS_VALG_figures.tar.gz

cd $CURDIR
FDSREPO=../../../fds
cd $FDSREPO
FDSREPO=`pwd`
cd $CURDIR

SMVREPO=../../../smv
cd $SMVREPO
SMVREPO=`pwd`
cd $CURDIR

echo ***files downloaded to $BUNDLEDIR
cd $CURDIR
exit 0
