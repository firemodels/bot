#!/bin/bash

CURDIR=`pwd`

cd files
FILESDIR=`pwd`

echo ***cleaning $FILESDIR
git clean -dxf

cd $CURDIR

DOWNLOADFILE ()
{
  TAG=$1
  FILE=$2
  echo downloading $FILE
  gh release download $TAG -p $FILE -D $FILESDIR  -R github.com/$GH_OWNER/$GH_REPO
}

COPYFILES ()
{
  TODIR=$1
  FILE=$2
  if [ -d $TODIR ]; then
    echo "*** untarring $FILE to $TODIR"
    cd $TODIR
    if [ -e $FILESDIR/$FILE ]; then
      tar xf $FILESDIR/$FILE > /dev/null 2>&1
    else
      echo "***error: $FILESDIR/$FILE does not exist"
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

COPYFILES $FDSREPO/Manuals/FDS_User_Guide/SCRIPT_FIGURES                FDS_UG_figures.tar.gz
COPYFILES $FDSREPO/Manuals/FDS_Technical_Reference_Guide/SCRIPT_FIGURES FDS_TG_figures.tar.gz
COPYFILES $FDSREPO/Manuals/FDS_Verification_Guide/SCRIPT_FIGURES        FDS_VERG_figures.tar.gz
COPYFILES $FDSREPO/Manuals/FDS_Validation_Guide/SCRIPT_FIGURES          FDS_VALG_figures.tar.gz

cd $CURDIR
exit 0
